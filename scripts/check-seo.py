"""Validate the maintained website or a packaged website: python scripts/check-seo.py [directory]."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, urljoin, unquote
import json
import sys
import xml.etree.ElementTree as ET

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1] / 'docs'
class Page(HTMLParser):
    def __init__(self):
        super().__init__(); self.canonical=[]; self.meta={}; self.links=[]; self.ids=[]; self.h1=0; self.titles=0
    def handle_starttag(self, tag, attrs):
        attrs=dict(attrs)
        if tag=='title': self.titles+=1
        if tag=='h1': self.h1+=1
        if 'id' in attrs: self.ids.append(attrs['id'])
        if tag=='meta': self.meta[attrs.get('name',attrs.get('property'))]=attrs.get('content','')
        if tag=='link' and attrs.get('rel')=='canonical': self.canonical.append(attrs['href'])
        if tag=='a': self.links.append(attrs.get('href',''))

pages={}
for path in root.glob('*.html'):
    page=Page(); page.feed(path.read_text(encoding='utf-8')); pages[path.name]=page
    assert page.titles==1 and page.h1==1, path
    assert len(page.ids)==len(set(page.ids)),path
    assert len(page.canonical)==1 and page.canonical[0].startswith('https://'),path
    assert not urlsplit(page.canonical[0]).query,path
    assert page.meta.get('description') and page.meta.get('og:title'),path
    assert page.meta.get('og:description')==page.meta['description'],path
    assert page.meta.get('og:url')==page.canonical[0],path
    for link in page.links:
        u=urlsplit(link)
        if not u.netloc and u.path.endswith('.html'): assert not u.query,(path,link)

ns={'s':'http://www.sitemaps.org/schemas/sitemap/0.9'}
urls=[n.text for n in ET.parse(root/'sitemap.xml').findall('s:url/s:loc',ns)]
expected={p.canonical[0] for p in pages.values() if 'noindex' not in p.meta.get('robots','')}
assert len(urls)==len(set(urls)) and set(urls)==expected, 'Sitemap differs from indexable pages'
assert 'noindex' in pages['start.html'].meta.get('robots','')
robots=(root/'robots.txt').read_text(encoding='utf-8')
home=pages['index.html'].canonical[0]
assert 'Sitemap: '+urljoin(home,'sitemap.xml') in robots
disallowed=[line.split(':',1)[1].strip() for line in robots.splitlines() if line.startswith('Disallow:')]
for u in urls: assert not any(urlsplit(u).path.startswith(d) for d in disallowed),u
for name,page in pages.items():
    for link in page.links:
        u=urlsplit(link)
        if u.scheme or u.netloc or u.path.startswith('/'):continue
        target=root/unquote(u.path) if u.path else root/name
        if target.is_dir(): target=target/'index.html'
        assert target.exists(),(name,link)
        if u.fragment and target.name in pages:assert unquote(u.fragment) in pages[target.name].ids,(name,link)
import re
blocks=re.findall(r'<script type="application/ld\+json">(.*?)</script>',(root/'index.html').read_text(encoding='utf-8'),re.S)
assert len(blocks)==1
schema=json.loads(blocks[0]);assert {x['@type'] for x in schema['@graph']}=={'Organization','WebSite'}
print(f'PASS: {len(pages)} page metadata/canonicals/internal links; {len(urls)} sitemap URLs; robots and JSON-LD')

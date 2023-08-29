import requests
import os
from urllib.parse import unquote, urlparse, ParseResult
import re
from pprint import pprint
from pathlib import Path
from json import dump
from bs4 import BeautifulSoup
from datetime import datetime

domain_to_scrape = 'updater.xlabs.dev'
new_url_root = urlparse('https://minopia.de/archive/') # ('https://xlabs-mirror.github.io/')
save_folder_path = Path('C:/Users/blusc/AppData/Local/Temp/xlabs-mirror.github.io')
html_file_extensions = ['html', 'htm']

def get_url(url: ParseResult):
    print("GET ", url.geturl())
    return requests.get(url.geturl())
def sanitize_filename(filename:str):
    # Remove invalid characters from the filename
    if filename.endswith("/"): filename += "index.html"
    filename = filename.removeprefix("https://").removeprefix("http://").replace("//", "/")
    return re.sub(r'[<>:"\\|?*]', '_', filename)
def remove_trailing_slash(string):
    if string.endswith("/"):
        string = string[:-1]
    return string
def prepend_html_banner(directory:Path, extensions:list, banner_html):
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(tuple(extensions)):
                file_path = directory / file
                with file_path.open(mode='r', encoding="utf-8") as file:
                    file_content = file.read()
                print(f"Inserting html banner into {file_path}")
                try:
                    soup = BeautifulSoup(file_content, 'html.parser')
                    if not soup.find(class_='banner'):
                        banner = soup.new_tag('div', attrs={'class': 'banner'})
                        banner.string = banner_html
                        if body_tag := soup.body:
                            body_tag.insert(0, banner)
                            new_content = soup.prettify()
                            with file_path.open(mode='w') as file:
                                file.write(new_content)
                except Exception as ex:
                    pprint(ex)
                    print("Failed to parse html, inserting raw")
                    if banner_html not in file_content:
                        new_content = banner_html + file_content
                        with file_path.open(mode='w', encoding="utf-8") as file:
                            file.write(new_content)
def replace_regex_in_files(directory:Path, extensions:list, regex, replacement):
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(tuple(extensions)):
                file_path = os.path.join(root, file)
                print(f"Replacing \"{regex}\" with \"{replacement}\" in \"{file_path}\"")
                with open(file_path, 'r', encoding="utf-8") as f:
                    content = f.read()
                modified_content = re.sub(regex, replacement, content)
                with open(file_path, 'w', encoding="utf-8") as f:
                    f.write(modified_content)
                print(f"Modified: {file_path}")
def create_sitemap(folder_path:Path):
    output_file = folder_path / "sitemap.xml"

    # Open the output file in write mode
    with output_file.open('w') as f:
        # Write the XML header
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n')

        # Recursively iterate over the folder and its contents
        for path in folder_path.glob('**/*'):
            # Skip directories
            if path.is_dir():
                continue

            # Extract the relative path and convert it to URL format
            relative_path = path.relative_to(folder_path)
            url = relative_path.as_posix()

            # Write the URL entry in the sitemap
            f.write(f'  <url>\n')
            f.write(f'    <loc>{url}</loc>\n')
            f.write(f'  </url>\n')

        # Write the XML footer
        f.write('</urlset>\n')
def scrape_archived_pages(domain, save_folder):
    # Create the save folder if it doesn't exist
    if not os.path.exists(save_folder):
        os.makedirs(save_folder)

    # Construct the URL for the web.archive.org API
    api_url = urlparse(f'https://web.archive.org/cdx/search/cdx?url={domain}/*&output=json&fl=original&collapse=urlkey')

    # Send a GET request to retrieve the list of archived pages
    response = get_url(api_url)

    if response.status_code == 200:
        # Extract the URLs from the response
        index_path = save_folder_path / "index.json"
        if not index_path.parent.is_dir(): index_path.parent.mkdir(parents=True, exist_ok=True)

        urls = response.json()
        with open(index_path, 'w') as file:
            dump(urls, file, indent=4)
            print(f'Saved: {index_path}')
        urls.pop(0)  # Remove the header row
        urls_len = len(urls)
        print(f"Got list of {urls_len} archived urls.")
        # Scrape and save the latest archived versions
        for i, url in enumerate(urls):
            try:
                original_url = urlparse(url[0])
                print(f"Processing url {i}/{urls_len}: {original_url.geturl()}")
                archive_url = urlparse(f'https://web.archive.org/web/{original_url.geturl()}')
                # Send a GET request to retrieve the latest archived version
                page_response = get_url(archive_url)

                if page_response.status_code == 200:
                    # Save the page content to a file in the save folder
                    decoded_url = unquote(original_url.geturl())
                    print("decoded_url:",decoded_url)
                    page_filename = remove_trailing_slash(sanitize_filename(decoded_url)) # + ".html"
                    print("page_filename:",page_filename)
                    # page_filepath = Path(page_filename)
                    page_filepath: Path = save_folder / page_filename
                    print("page_filepath:",page_filepath)
                    if "." not in page_filepath.name: page_filepath = page_filepath.with_suffix(".html")
                    if not page_filepath.parent.exists(): page_filepath.parent.mkdir(parents=True, exist_ok=True)
                    with open(page_filepath, 'wb') as file:
                        file.write(page_response.content)
                        print(f'Saved: {page_filename}')
                else:
                    print(f'Failed to retrieve: {archive_url.geturl()}')
            except Exception as ex:
                pprint(ex)
                # input("Press any key to continue, CTRL+C to abort ...")
    else:
        print('Failed to retrieve archived pages.')

# scrape_archived_pages(domain_to_scrape, save_folder_path)
# create_sitemap(save_folder_path / domain_to_scrape)
# input("Press any key to replace domain ... ")
# replace_regex_in_files(save_folder_path, html_file_extensions, domain_to_scrape, new_url_root.hostname)

# replace_regex_in_files(Path("C:/Users/blusc/AppData/Local/Temp/xlabs-mirror.github.io/"), ['.htm', '.html'], domain_to_scrape, new_url_root.hostname)
# prepend_html_banner(save_folder_path, html_file_extensions, f"""<div style="background-color: #f8f9fa; padding: 10px; text-align: center;">
#         <p>This page has been saved for archival purposes on {datetime.now()}.</p>
#     </div>""")
import os
import re
import requests
from packaging import version

def get_latest_stable_version():
    url = "https://dist.torproject.org/torbrowser/"
    response = requests.get(url)
    response.raise_for_status()
    
    # Find all version directories
    versions = re.findall(r'>\d+\.\d+\.\d+/<', response.text)
    # Clean up versions and filter out alpha/beta
    stable_versions = [v.strip('>/<') for v in versions if 'a' not in v and 'b' not in v]
    
    if not stable_versions:
        raise Exception("No stable versions found")
        
    # Return highest version
    return str(max(map(version.parse, stable_versions)))

def download_tor_browser(version):
    filename = f"tor-browser-windows-x86_64-portable-{version}.exe"
    url = f"https://dist.torproject.org/torbrowser/{version}/{filename}"
    
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        
        with open(filename, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        return filename
    except Exception as e:
        raise Exception(f"Failed to download Tor Browser: {str(e)}")

def cleanup_old_versions(current_version):
    for file in os.listdir('.'):
        if file.startswith('tor-browser') and file.endswith('.exe'):
            if current_version not in file:
                try:
                    os.remove(file)
                except Exception as e:
                    print(f"Failed to remove old version {file}: {str(e)}")

def main():
    try:
        latest_version = get_latest_stable_version()
        downloaded_file = download_tor_browser(latest_version)
        cleanup_old_versions(latest_version)
        print(f"Successfully downloaded Tor Browser {latest_version}")
    except Exception as e:
        print(f"Error: {str(e)}")
        exit(1)

if __name__ == "__main__":
    main()

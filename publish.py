import os
import sys
import json
from packaging import version
from zipfile import ZIP_DEFLATED, ZipFile

option_to_index_map = {
    "major" : 0,
    "minor" : 1,
    "patch": 2,
    "increment": 3,
}

if len(sys.argv) != 2:
    print("Invalid command line argument count!\nMust be 1 (increment method)")
    exit(-1)

if not sys.argv[1].lower() in option_to_index_map.keys():
    print(f"Invalid command line argument\nMust be one of the following values!: {option_to_index_map.keys()}")
    exit(-1)

# increment the package version

incr_method = str.lower(sys.argv[1].lower())

package = None

with open("package.json", 'r+') as package_data:
    # retrieve package version from the json file
    
    package = json.load(package_data)
    
    package_version = list(version.parse(package["version"]).release)
    
    # increment package version based on command line arguments
    
    package_version[option_to_index_map[incr_method]] += 1
    
    for i in range(option_to_index_map[incr_method] + 1, len(package_version)):
        package_version[i] = 0
    
    # write the new version back to the json file
    
    
    old_version = package["version"]
    package["version"] = str(version.Version('.'.join([str(n) for n in package_version])))
    
    print()
    print(f"Bump version from {old_version} to {package['version']}")
    
    with open("package.json", 'w') as package_out:
        json.dump(package, package_out, indent=4)

# add all package files to a .asesprite-extension zip file

target_files = [ "package.json" ] + [ lua_script for lua_script in os.listdir('./') if lua_script.endswith('.lua') ]

extension_location = "publish/aselapse.aseprite-extension"

if os.path.isfile(extension_location):
    os.remove(extension_location)

print()
with ZipFile(extension_location, 'w', ZIP_DEFLATED) as extension_zip:
    for file in target_files:
        print(f"Adding {file} to extension")
        extension_zip.write(file, compresslevel=5)

print()
print(f"Published extension at '{extension_location}'!")

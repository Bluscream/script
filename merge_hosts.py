import sys

def merge_hosts(files, output_file):
    hosts = {}

    # Process each file
    for filename in files:
        print(f"Processing file: {filename}")
        with open(filename, 'r') as f:
            for line in f:
                line = line.strip()
                # Ignore blank lines or lines starting with "!"
                if line == '' or line[0] == "!":
                    print(f"Ignoring line: {line}")
                    continue
                # print(f"Processing line: {line}")
                parts = line.split(maxsplit=1)
                ip = parts[0]
                rest = parts[1] if len(parts) > 1 else ''
                names_comments = rest.split('#', maxsplit=1)
                names = set(names_comments[0].split())
                if ip not in hosts:
                    print("new ip: "+ip)
                    hosts[ip] = {'names': set(), 'comments': set()}
                hosts[ip]['names'].update(names)
                comment = '#' + names_comments[1] if len(names_comments) > 1 else ''
                if comment:
                    hosts[ip]['comments'].add(comment)
            print(hosts)

    # Write the output file
    print(f"Writing to output file: {output_file}")
    with open(output_file, 'w') as f:
        for ip in sorted(hosts.keys()):
            line = ip+'\t\t\t'+' '.join(sorted(hosts[ip]['names'])) + ' ' + ' # '.join(sorted(hosts[ip]['comments']))
            f.write(line.strip()+"\n")

# Usage
if __name__ == "__main__":
    input_files = sys.argv[1:-1]
    output_file = sys.argv[-1]
    merge_hosts(input_files, output_file)

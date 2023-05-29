$hostsFiles = @()
Write-Output """$($MyInvocation.MyCommand.Path)"" $args"
Write-Output "hostsFiles: $hostsFiles"

$mergedFile = "merged_hosts"

# Create an empty hashtable to store the host entries
$hostEntries = @{}

# Process each hosts file
foreach ($file in $hostsFiles) {
    # Read the content of the current hosts file
    $content = Get-Content $file

    # Process each line in the file
    foreach ($line in $content) {
        # Skip comments and empty lines
        if (-not ($line -match '^\s*(#|$)')) {
            # Split the line into IP address and hostnames
            $ip, $hostnames = $line -split '\s+'
            
            # Trim leading/trailing whitespace from hostnames
            $hostnames = $hostnames.Trim()

            # Check if the IP address already exists in the hashtable
            if ($hostEntries.ContainsKey($ip)) {
                # Add new hostnames to the existing IP address entry
                $hostEntries[$ip] += "," + $hostnames
            }
            else {
                # Create a new entry for the IP address and hostnames
                $hostEntries[$ip] = $hostnames
            }
        }
    }
}

# Generate the merged hosts file content
$mergedContent = foreach ($entry in $hostEntries.GetEnumerator()) {
    $ip = $entry.Key
    $hostnames = $entry.Value

    # Combine the IP address and hostnames into a single line
    "{0}\t{1}" -f $ip, $hostnames
}

# Write the merged hosts file content to the output file
$mergedContent | Set-Content -Path $mergedFile

Write-Host "Hosts files merged successfully. Merged file saved as: $mergedFile"

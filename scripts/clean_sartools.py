#!/usr/bin/env python3

import sys

def read_html_file(filename):
    with open(filename, 'r') as f:
        return f.readlines()

def filter_block(from_tag, to_tag, lines):
    output = True
    result = []
    for line in lines:
        if line.strip().startswith(from_tag):
            output = False
        if output:
            result.append(line)
        if to_tag in line:
            output = True
    return result

def replace_block(from_str, to_str, lines):
    return [line.replace(from_str, to_str) for line in lines]

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 multiqc_cleaner.py <file.html>")
        sys.exit(1)

    filename = sys.argv[1]
    html = read_html_file(filename)

    # Remove side bar div and cleanup columns
    html = filter_block('<div class="col-xs-12 col-sm-4 col-md-3">', '</div>', html)
    html = replace_block(
        'class="toc-content col-xs-12 col-sm-8 col-md-9"',
        'class="toc-content col-xs-12 col-sm-12 col-md-12"',
        html
    )

    # Remove header
    html = filter_block('<div class="fluid-row" id="header">', '</p>', html)

    # Write cleaned output
    output_filename = filename.replace('.html', '_cleaned.html')
    with open(output_filename, 'w') as f:
        f.writelines(html)

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
import sys

def filter_block(from_tag, to_tag, lines):
    output = True
    result = []

    for line in lines:
        if line.strip().startswith(from_tag):
            output = False
        if output:
            result.append(line)
        if line.strip().startswith(to_tag):
            output = True

    return result

def main():
    if len(sys.argv) < 2:
        print("Usage: python clean_multiqc.py <file.html>")
        sys.exit(1)

    filename = sys.argv[1]
    try:
        with open(filename, 'r') as f:
            html = f.readlines()
    except FileNotFoundError:
        print(f"Could not open {filename}")
        sys.exit(1)

    # Perform filters
    html = filter_block('<div class="side-nav-wrapper">', '</div>', html)
    html = filter_block('<div class="mainpage">', ' ', html)
    html = filter_block('      <a href="#">', '      </a>', html)
    html = filter_block('<h1 id="page_title">', '</p>', html)
    html = filter_block('<div id="analysis_dirs_wrapper">', '</div>', html)
    html = filter_block('<div class="alert alert-info alert-dismissible hidden-print" id="mqc_welcome" style="display: none;">', '</div>', html)
    html = filter_block('    <a href="http://www.scilifelab.se/" target="_blank" class="pull-right">', '    </a>', html)

    # Write cleaned output
    output

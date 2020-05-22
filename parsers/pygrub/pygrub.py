import json
import sys


def parse_config(file):
    config = open(file, 'r')

    lines = config.read()
    variables = {}
    entries = {}

    # read variables
    for line in lines.split('\n'):
        parse_variable(line, variables)

    parse_entries(lines, entries)

    config.close()
    return {
        'variables': variables,
        'entries': entries
    }


def parse_variable(line, dictionary):
    line_parts = line.split(' ', 1)
    # Set variable=blah
    if line_parts[0] == 'set':
        variable_parts = line_parts[1].split('=')
        variable_name = variable_parts[0]
        variable_value = variable_parts[1].replace('"', '')
        dictionary[variable_name] = variable_value


def parse_entries(config, dictionary):
    lines = list(filter(lambda x: 'set' not in x, config.split('menuentry')))
    for line in lines:
        full_entry = line.split('\n')
        entry_name = list(filter(lambda x: len(x) > 1, full_entry[0].split('"')))[0]
        classes = strip_classes(list(filter(lambda x: 'class' in x, full_entry[0].split('--'))))
        kernel = full_entry[1].strip()
        ramdisk = full_entry[2].strip()
        dictionary[entry_name] = {'name': entry_name, 'classes': classes, 'kernel': kernel, 'ramdisk': ramdisk}


def strip_class(class_entry):
    class_entry = class_entry.replace('class', '')
    class_entry = class_entry.replace('{', '')
    return class_entry.strip()


def strip_classes(classes):
    return list(map(lambda x: strip_class(x), classes))


if __name__ == "__main__":
    if len(sys.argv) == 2:
        result = parse_config(sys.argv[1])
        print(json.dumps(result))
    else:
        print('No grub.cfg passed')

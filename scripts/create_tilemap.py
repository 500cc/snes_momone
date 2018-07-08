import argparse
import csv
import binascii

parser = argparse.ArgumentParser(description='Tilemap creation for SNES')
parser.add_argument('levelfile')

args = parser.parse_args()

level_csv = open(args.levelfile)
level_reader = csv.reader(level_csv)
level_list = []
level_dict = {'0': '0000', '1': '0204'}
level_text = ''
metadata_text = ''

for row in level_reader:
    level_list.append(row)

# level_list = list(map(list, zip(*level_list)))  # transpose

for row in level_list:
    for element in row:
        metadata_text += element
        level_text += level_dict[element]

metadata_text_hex = format(int(metadata_text, 2), 'x').zfill(int(len(metadata_text)/4))

print(len(level_text))
output_bin = open('level.bin', 'wb')
metadata_bin = open('metadata.bin', 'wb')
output_bin.write(binascii.unhexlify(level_text))
metadata_bin.write(binascii.unhexlify(metadata_text_hex))

level_csv.close()
output_bin.close()
metadata_bin.close()

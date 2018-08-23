from PIL import Image
import argparse
import binascii

parser = argparse.ArgumentParser(description='Image convertion for SNES')
parser.add_argument('imgfile')
parser.add_argument('-b', '--background', action='store_true')
parser.add_argument('-bb', '--blueback', action='store_true')
args = parser.parse_args()

img = Image.open(args.imgfile)
width, height = img.size
colors = []
palette = []
pattern = ''

if args.background:
    color_depth = 2
else:
    color_depth = 4

for color in img.getcolors():
    colors.append(color[1])
print(img.getcolors())
print('found {} colors'.format(len(colors)))

if args.blueback:
    print('use blueback')
    colors.insert(0, (0, 0, 255))
else:
    print('choose background color')
    i = input('>> ')
    i = int(i)
    colors[0], colors[i] = colors[i], colors[0]


for color in colors:
    palette_buffer = '0'
    for element in [2, 1, 0]:
        palette_buffer += format(int(color[element] / 8), 'b').zfill(5)
    palette.append(format(int(palette_buffer, 2), 'x').zfill(4))

images = []

for y in range(int(height / 8)):
    for x in range(int(width / 8)):
        images.append(img.crop((x * 8, y * 8, x * 8 + 8, y * 8 + 8)))
print(images)

for n in images:
    upper_pattern = ''
    lower_pattern = ''
    for y in range(8):
        pattern_buffer = ''
        sub_pattern = ['', '', '', '']
        for x in range(8):
            pattern_buffer += format(colors.index(n.getpixel((x, y))), 'b').zfill(color_depth)
        for i in range(len(pattern_buffer)):
            sub_pattern[i % color_depth] += pattern_buffer[i]
        lower_pattern += sub_pattern[1] + sub_pattern[0]
        upper_pattern += sub_pattern[3] + sub_pattern[2]
    pattern += upper_pattern + lower_pattern

fout = open('{}_pattern.bin'.format(args.imgfile[:args.imgfile.find('.')]), 'wb')
s = format(int(pattern, 2), 'x').zfill(int(width * height))
print(len(s))
fout.write(binascii.unhexlify(s))

fout = open('{}_palette.bin'.format(args.imgfile[:args.imgfile.find('.')]), 'wb')
s = ''.join(palette)
s = ''.join(reversed([s[i: i + 2] for i in range(0, len(s), 2)]))
fout.write(binascii.unhexlify(''.join(reversed([s[i: i + 4] for i in range(0, len(s), 4)]))))

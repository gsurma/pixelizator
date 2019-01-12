from PIL import Image
import sys


if len(sys.argv) > 1:
	pixel_size = int(sys.argv[1])
else:
	pixel_size = 8

if len(sys.argv) > 2:
	scale = int(sys.argv[2])
else:
	scale = 1

image = Image.open('input.png')
downscaled_image = image.resize((image.size[0]/pixel_size,
							   	image.size[1]/pixel_size),
								Image.NEAREST)
upscaled_image = downscaled_image.resize((downscaled_image.size[0]*pixel_size*scale,
										downscaled_image.size[1]*pixel_size*scale),
										Image.NEAREST)
upscaled_image.save('output.png')
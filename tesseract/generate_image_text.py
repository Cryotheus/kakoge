try: from PIL import Image
except ImportError: import Image

import pathlib
import pytesseract

#if you don't have tesseract executable in your PATH, include the following:
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract'
#example tesseract_cmd = r'C:\Program Files (x86)\Tesseract-OCR\tesseract'

config_line = "kakoge"
language_order = ("kor", "kor_kakoge", "kor_rekakoge", "script/Hangul", "kor+kor_kakoge+kor_rekakoge")
threshold = 100

#image_to_boxes
#image_to_data
#image_to_string

#tesseract configuration parameters
#tessedit_zero_rejection T
#tessedit_reject_doc_percent=65.00 %rej allowed before rej whole doc
#tessedit_reject_block_percent=45.00 %rej allowed before rej whole block
#tessedit_reject_row_percent=40.00 %rej allowed before rej whole row
#tessedit_whole_wd_rej_row_percent=70.00 Number of row rejects in whole word rejects which prevents whole row rejection
#tessedit_preserve_blk_rej_perfect_wds=true Only rej partially rejected words in block rejection
#tessedit_preserve_row_rej_perfect_wds=true Only rej partially rejected words in row rejection
#tessedit_reject_bad_qual_wds=true Reject all bad quality wds
#tessedit_minimal_rejection=false Only reject tess failures
#tessedit_zero_rejection=false Don't reject ANYTHING
#tessedit_zero_kelvin_rejection=false Don't reject ANYTHING AT ALL

#tessedit_reject_bad_qual_wds F
#tessedit_reject_doc_percent 90
#tessedit_reject_block_percent 85
#tessedit_reject_row_percent 80
#tessedit_preserve_blk_rej_perfect_wds F
#tessedit_preserve_row_rej_perfect_wds F
#tessedit_reject_bad_qual_wds F
#tessedit_zero_rejection T
#tessedit_minimal_rejection F
#tessedit_zero_kelvin_rejection T
#bland_unrej T
#textord_no_rejects T

def has_crops(product_path):
	return product_path.joinpath("crops").exists()

def scan(image_file):
	for language in language_order:
		text = pytesseract.image_to_string(
			image_file,
			lang=language,
			timeout=5,
			config=config_line
		)
		
		if text != "":
			print(language)
			
			return text
	return ""

def get_crops(product_path):
	count = 0
	count_cleanup = 0
	count_mono = 0
	crop_path = product_path.joinpath("crops")
	success = 0
	
	for member in crop_path.iterdir():
		if member.suffix == ".png":
			count += 1
			image_file = Image.open(member.as_posix())
			text = scan(image_file)
			
			if text == "":
				image_file = image_file.convert('L') #grayscale
				image_file = image_file.point(lambda p: 255 if p > threshold else 0) #threshold
				
				text = scan(image_file)
				
				if text == "":
					image_file = image_file.convert('1') # to mono
					text = scan(image_file)
				    
					if text != "": count_mono += 1
				#image_file.save(member.with_name(member.stem + "_tesseract.png").as_posix())
				
				if text != "": count_cleanup += 1
			if text == "": print("no text\n")
			else:
				print("text\n")
				
				file = open(member.with_suffix(".txt"), "wb")
				success += 1
				
				file.write(text.encode('utf-8'))
				file.close()
	print(f"Found text in {success} of {count} file(s).\nWe had to cleanup {count_cleanup} image(s) and {count_mono} of them needed a mono conversion.")

def get_downloads(path):
	if path.exists():
		downloads = {}
		
		print("Available by ID:")
		
		for member in path.iterdir():
			if member.is_dir() and has_crops(member):
				product_id = member.stem
				downloads[product_id] = member
				
				print("    " + product_id)
		
		return downloads
	else:
		input("missing download folder")
		exit()

def get_data_path(file):
	for parent in pathlib.Path(file).parents[:]:
		stem = parent.stem
		
		if stem == "garrysmod": return parent.joinpath('data/kakoge')
		elif stem == "": return False

def query_id(downloads):
	product_id = input("id:")
	
	if product_id in downloads:
		product_path = downloads[product_id]
		get_crops(product_path)
		query_id(downloads)

if __name__ == "__main__":
	data_path = get_data_path(__file__)
	
	if data_path:
		download_path = data_path.joinpath("download")
		
		if data_path:
			downloads = get_downloads(download_path)
			
			query_id(downloads)
	else: input("Make sure this file is anywhere inside your garrysmod folder. This can be inside the kakoge addon folder if you'd like.")

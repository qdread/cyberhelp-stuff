# Convert all PDFs in a directory into TIFFs with the desired resolution.
# QDR / 13 Dec 2019

# By default this will convert all pdfs in the current working directory into tiff images with 500DPI resolution
# You can also specify a vector of file paths if you do not want to convert all pdfs in the directory or if you want to convert pdfs in a different directory.
# The tiff file will have the same name as the pdf file and be output in the same directory.
# See https://stackoverflow.com/questions/75500/best-way-to-convert-pdf-files-to-tiff-files

pdf2tif <- function(dpi = 500, pdf_files = dir('.', pattern = '*.pdf')) {
  for (pdf_file in pdf_files) {
    tif_file <- gsub('.pdf', '.tif', pdf_file)
    system2('gs', args = paste0('-dNOPAUSE -q -r', dpi, 'x', dpi, ' -sDEVICE=tiff24nc -dBATCH -sOutputFile=', tif_file, ' ', pdf_file))
    message('Converted ', pdf_file, ' to ', tif_file)
  }
}

#' Household id to qr code print
#' 
#' Overlay qr code on image
#' @param base_img_path The path to the image that will be overlayed with a qr code
#' @param hh_id The household ID
#' @import magick
#' @import qrcode
#' @import tidyverse
#' @return overlayed image
#' @export

hh_qr_code_print <- function(base_img_path, hh_id) {
  # create qr code matrix
  x <- qrcode_gen(hh_id, plotQRcode=F, dataOutput=T, ErrorCorrectionLevel = 'H')
  x <- as.data.frame(x)
  y <- x
  y$id <- rownames(y)
  y <- gather(y, "key", "value", colnames(y)[-ncol(y)])
  y$key = factor(y$key, levels=rev(colnames(x)))
  y$id = factor(y$id, levels=rev(rownames(x)))
  
  # get qr code plot
  fig <- image_graph()
  print(ggplot(y, aes_(x=~id, y=~key)) + geom_tile(aes_(fill=~value), alpha=1) +
    scale_fill_gradient(low="white", high='black') +
    theme_void() + theme(legend.position='none'))
  dev.off()
  img_inset <- image_scale(fig, "165x") 

  # get base image
  base_img <- image_read(base_img_path)
  base_img <- image_scale(base_img, geometry = "50%x")
  
  # layer images
  img_with_inset <- base_img %>% image_composite(
    img_inset,
    offset = "+420+40"
  )
  print(img_with_inset)
}


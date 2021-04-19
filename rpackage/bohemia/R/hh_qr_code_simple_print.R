#' Household id to qr code print (simple)
#' 
#' Overlay qr code on image
#' @param hh_id The household ID
#' @param save_file Where to save the file
#' @import magick
#' @import qrcode
#' @import tidyverse
#' @return overlayed image
#' @export

hh_qr_code_print_simple <- function(hh_id = 'ABC-123', save_file = NULL, ...) {
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
  g <- ggplot(y, aes_(x=~id, y=~key)) + geom_tile(aes_(fill=~value), alpha=1) +
    scale_fill_gradient(low="white", high='black') +
    theme_void() + theme(legend.position='none',
                         plot.title = element_text(hjust = 0.5, size = 25)) +
    labs(title = hh_id)

  if(!is.null(save_file)){
    ggsave(filename = save_file, g,
           ...)
  } else {
    print(g)
  }
}


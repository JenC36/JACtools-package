#'
#' Shift the Legend of a Facetted Plot to an Empty Facet 
#'
#' This function places the legend of a facetted plot with an uneven number of facets
#'    into the empty space (the empty facet area). \cr
#'    This function is taken from stack overflow: <https://stackoverflow.com/questions/54438495/shift-legend-into-empty-facets-of-a-faceted-plot-in-ggplot2> \cr
#'    See also <https://stackoverflow.com/questions/28496764/add-textbox-to-facet-wrapped-layout-in-ggplot2>  \cr
#'       and the cowplot package <https://cran.r-project.org/web/packages/cowplot/vignettes/introduction.html>
#'  
#'
#' @param p A ggplot object.
#' @keywords ggplot2 facet legend cowplot
#' @export
#' @examples
#' 
#' p <- (ggplot2::ggplot(diamonds, aes(x = carat, fill = cut)) 
#'       + geom_density(position = "stack") + facet_wrap(~ color) )
#' library(grid)
#' grid.draw(shift_legend(p))
#' 
#' p.new <- p +
#'   guides(fill = guide_legend(title.position = "top",
#'                             label.position = "bottom",
#'                             nrow = 1)) +
#'   theme(legend.direction = "horizontal")
#' grid.draw(shift_legend(p.new))

shift_legend <- function(p){
	
	# check if p is a valid object
	if(!"gtable" %in% class(p)){
		if("ggplot" %in% class(p)){
			gp <- ggplotGrob(p) # convert to grob
		} else {
			message("This is neither a ggplot object nor a grob generated from ggplotGrob. Returning original plot.")
			return(p)
		}
	} else {
		gp <- p
	}
	
	# check for unfilled facet panels
	facet.panels <- grep("^panel", gp[["layout"]][["name"]])
	empty.facet.panels <- sapply(facet.panels, function(i) "zeroGrob" %in% class(gp[["grobs"]][[i]]))
	empty.facet.panels <- facet.panels[empty.facet.panels]
	if(length(empty.facet.panels) == 0){
		message("There are no unfilled facet panels to shift legend into. Returning original plot.")
		return(p)
	}
	
	# establish extent of unfilled facet panels (including any axis cells in between)
	empty.facet.panels <- gp[["layout"]][empty.facet.panels, ]
	empty.facet.panels <- list(min(empty.facet.panels[["t"]]), min(empty.facet.panels[["l"]]),
			max(empty.facet.panels[["b"]]), max(empty.facet.panels[["r"]]))
	names(empty.facet.panels) <- c("t", "l", "b", "r")
	
	# extract legend & copy over to location of unfilled facet panels
	guide.grob <- which(gp[["layout"]][["name"]] == "guide-box")
	if(length(guide.grob) == 0){
		message("There is no legend present. Returning original plot.")
		return(p)
	}
	gp <- gtable::gtable_add_grob(x = gp,
			grobs = gp[["grobs"]][[guide.grob]],
			t = empty.facet.panels[["t"]],
			l = empty.facet.panels[["l"]],
			b = empty.facet.panels[["b"]],
			r = empty.facet.panels[["r"]],
			name = "new-guide-box")
	
	# squash the original guide box's row / column (whichever applicable)
	# & empty its cell
	guide.grob <- gp[["layout"]][guide.grob, ]
	if(guide.grob[["l"]] == guide.grob[["r"]]){
		gp <- cowplot::gtable_squash_cols(gp, cols = guide.grob[["l"]])
	}
	if(guide.grob[["t"]] == guide.grob[["b"]]){
		gp <- cowplot::gtable_squash_rows(gp, rows = guide.grob[["t"]])
	}
	gp <- cowplot::gtable_remove_grobs(gp, "guide-box")
	
	return(gp)
}










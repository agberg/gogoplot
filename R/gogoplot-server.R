
gogoplot_server <- function(.data, data_name) {

  # create a data-object with the same name as the .data input
  # NOTE: this is created here so it is available in the environment
  #       of the returned server function
  assign(data_name, .data)

  function(input, output, session) {

    # dynamic UI input elements
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    choices <- select_choices(.data)
    output$xvar <- shiny::renderUI({
      selectInput("xvar", "x variable:",
                  choices = choices, selected = CONST_NONE)
    })
    output$yvar <- shiny::renderUI({
      selectInput("yvar", "y variable:",
                  choices = choices, selected = CONST_NONE)
    })
    output$color <- shiny::renderUI({
      selectInput("color", NULL,
                  choices = choices, selected = CONST_NONE)
    })
    output$alpha <- shiny::renderUI({
      sliderInput("alpha", "alpha",
                  min = 0, max = 1, value = 1, step = 0.1)
    })
    output$facet_row <- shiny::renderUI({
      selectInput("facet_row", "facet rows:",
                  choices = choices, selected = CONST_NONE)
    })
    output$facet_col <- shiny::renderUI({
      selectInput("facet_col", "facet cols:",
                  choices = choices, selected = CONST_NONE)
    })
    output$size_set <- shiny::renderUI({
      sliderInput("size_set", "size setting:",
                  min = 1, max = 5, value = 2, step = 0.5)
    })
    output$size_map <- shiny::renderUI({
      selectInput("size_map", "size mapping:",
                  choices = choices, selected = CONST_NONE)
    })

    # Render the plot
    output$plot_display <- shiny::renderPlot({
      if (input$auto_plot == TRUE) {
        plot <- plot()
      } else {
        input$btn_update
        plot <- isolate(plot())
      }
      plot
    })

    plot <- shiny::reactive({
      validate(
        need(input$xvar, 'Select an x variable.'),
        need(input$yvar, 'Select a y variable.'),
        need(input$xvar != CONST_NONE, 'Select an x variable.'),
        need(input$yvar != CONST_NONE, 'Select a y variable.')
      )

      # empty plot object
      p <- new_gogoplot(ggplot(!!sym(data_name),
                               aes(!!sym(input$xvar), !!sym(input$yvar))))
      p <- add_geom_point(p, input)
      p <- add_guides(p, input)
      p <- add_labs(p, input)
      p <- add_facet_grid(p, input)
      p
    })

    # ---- plot_code ----
    plot_code <- shiny::reactive({
      attr(plot(), "gogoplot")
    })

    output$data_table <- shiny::renderDataTable({
      .data
    }, options = list(pageLength = 5))

    # indicate if plot is stale
    shiny::observeEvent(plot(), {
      if (input$auto_plot == T) {
        updateCheckboxInput(session, 'auto_plot', label = 'auto-update')
      } else {
        updateCheckboxInput(session, 'auto_plot', label = 'auto-update (*)')
      }
    })

    # buttons
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # update plot
    shiny::observeEvent(input$btn_update, {
      updateCheckboxInput(session, 'auto_plot', label = 'auto-update')
    })

    # return plot code
    shiny::observeEvent(input$btn_code, {
      code_str <- paste0(plot_code(), collapse = " +\n  ")
      # return function call
      if(rstudioapi::isAvailable()){
        rstudioapi::insertText(text = code_str)
        shiny::stopApp()
      } else{
        shiny::stopApp(code_str)
      }
    })

    # return plot object
    shiny::observeEvent(input$btn_plot, {
      shiny::stopApp(plot())
    })

    # download plot image
    output$btn_save <- downloadHandler(
      filename = function() {
        paste0(Sys.Date(), '-plot.png')
      },
      content = function(con) {
        ggsave(con, output$plot, device = 'png')
      }
    )
  }
}

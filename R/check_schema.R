#' Check a Table Schema object
#'
#' Check if an object is a list describing a Table Schema and (optionally)
#' compare against a provided data frame.
#'
#' @param schema List describing a Table Schema.
#' @param data A data frame against which the Table Schema must be compared.
#' @return `schema` invisibly or an error.
#' @family check functions
#' @noRd
check_schema <- function(schema, data = NULL) {
  # Check schema is list with property fields
  if (
    !is.list(schema) ||
    !"fields" %in% names(schema) ||
    !is.list(schema["fields"])
  ) {
    cli::cli_abort(
      "{.arg schema} must be a list with a {.field fields} property.",
      class = "frictionless_error_schema_invalid"
    )
  }
  fields <- schema$fields

  # Check fields have names
  field_names <- purrr::map_chr(fields, ~ .x$name %||% NA_character_)
  fields_without_name <- as.character(which(is.na(field_names)))
  if (any(is.na(field_names))) {
    cli::cli_abort(
      c(
        "All fields in {.arg schema} must have a {.field name} property.",
        "x" = "Field{?s} {fields_without_name} {?doesn't/don't} have a
               {.field name}."
      ),
      class = "frictionless_error_fields_without_name"
    )
  }

  # Check fields have valid types (a mix of valid types and undefined is ok)
  field_types <- purrr::map_chr(fields, ~ .x$type %||% NA_character_)
  valid_types <- c(
    "string", "number", "integer", "boolean", "object", "array", "date", "time",
    "datetime", "year", "yearmonth", "duration", "geopoint", "geojson", "any",
    NA_character_
  )
  invalid_types <- setdiff(field_types, valid_types)
  if (length(invalid_types) > 0) {
    cli::cli_abort(
      c(
        "All fields in {.arg schema} must have a valid {.field type} property.",
        "x" = "Type{?s} {.val {invalid_types}} {?is/are} invalid."
      ),
      class = "frictionless_error_fields_type_invalid"
    )
  }

  # Check required value
  field_required <- purrr::map_chr(fields, ~ .x$constraints$required %||% NA)

  # Check data when present
  if (!is.null(data)) {
    check_data(data)

    col_names <- colnames(data)
    if (!all(col_names %in% field_names[field_required])) {
      cli::cli_abort(
        c(
          "Field names in {.arg schema} must match column names in {.arg data}.",
          "i" = "Field name{?s}: {.val {field_names}}.",
          "i" = "Column name{?s}: {.val {col_names}}."
        ),
        class = "frictionless_error_fields_colnames_mismatch"
      )
    }
  }

  invisible(schema)
}

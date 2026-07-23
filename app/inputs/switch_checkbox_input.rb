# frozen_string_literal: true

# SwitchCheckboxInput is a custom input type for SimpleForm that renders a checkbox as an optics (v0.5.0+) switch control
#
# Options:
#   :small - renders a smaller switch control
#   :label_after_input - renders the label after the switch control
#   :wrapper - the wrapper to use for this input, defaults to :inline_switch_wrapper. :switch_wrapper is also available.
#
# Usage:
# <%= f.input :my_field, as: :switch_checkbox %>
# <%= f.input :my_field, as: :switch_checkbox, small: true %>
# <%= f.input :my_field, as: :switch_checkbox, disabled: true %>
# <%= f.input :my_field, as: :switch_checkbox, label_after_input: true %>
# <%= f.input :my_field, as: :switch_checkbox, wrapper: :switch_wrapper %>
class SwitchCheckboxInput < SimpleForm::Inputs::BooleanInput
  def input(wrapper_options = nil)
    switch = switch_group(wrapper_options)
    options[:label_after_input] ? switch + label(wrapper_options) : label(wrapper_options) + switch
  end

  def input_html_classes
    []
  end

  private

  def switch_group(wrapper_options)
    template.content_tag(:div, class: "switch #{'switch--small' if options[:small]}") do
      check_box_tag(wrapper_options) + label(wrapper_options)
    end
  end

  def check_box_tag(wrapper_options)
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    return build_check_box(unchecked_value, merged_input_options) if include_hidden?

    build_check_box_without_hidden_field(merged_input_options)
  end
end

'use strict';
{
    const $ = django.jQuery;
    $.fn.formset = function(opts) {
        const options = $.extend({}, $.fn.formset.defaults, opts);
        const $this = $(this);
        const $parent = $this.parent();

        const updateElementIndex = function(el, prefix, ndx) {
            const id_regex = new RegExp(`(${prefix}-(\\d+|__prefix__))`);
            const replacement = `${prefix}-${ndx}`;
            if ($(el).prop("for")) {
                $(el).prop("for", $(el).prop("for").replace(id_regex, replacement));
            }
            if (el.id) {
                el.id = el.id.replace(id_regex, replacement);
            }
            if (el.name) {
                el.name = el.name.replace(id_regex, replacement);
            }
        };

        const totalForms = $(`#id_${options.prefix}-TOTAL_FORMS`).prop("autocomplete", "off");
        let nextIndex = parseInt(totalForms.val(), 10) || 0;
        const maxForms = $(`#id_${options.prefix}-MAX_NUM_FORMS`).prop("autocomplete", "off");
        const minForms = $(`#id_${options.prefix}-MIN_NUM_FORMS`).prop("autocomplete", "off");
        let addButton;

        const addInlineAddButton = function() {
            if (addButton === null) {
                if ($this.prop("tagName") === "TR") {
                    const numCols = $this.eq(-1).children().length;
                    $parent.append(`<tr class="${options.addCssClass}" role="presentation"><td colspan="${numCols}"><a role="button" class="addlink" href="#" aria-label="Add another ${options.addText.toLowerCase()}">${options.addText}</a></td></tr>`);
                    addButton = $parent.find("tr:last a");
                } else {
                    $this.filter(":last").after(`<div class="${options.addCssClass}"><a role="button" class="addlink" href="#" aria-label="Add another ${options.addText.toLowerCase()}">${options.addText}</a></div>`);
                    addButton = $this.filter(":last").next().find("a");
                }
                addButton.addClass('inline-add-button'); // For styling
            }
            addButton.on('click', addInlineClickHandler);
        };

        const addInlineClickHandler = function(e) {
            e.preventDefault();
            const template = $(`#${options.prefix}-empty`);
            if (!template.length) return; // Error handling: ensure template exists
            const row = template.clone(true);
            row.removeClass(options.emptyCssClass)
               .addClass(options.formCssClass)
               .attr({
                   "id": `${options.prefix}-${nextIndex}`,
                   "role": "form"
               });
            addInlineDeleteButton(row);
            row.find("*").each(function() {
                updateElementIndex(this, options.prefix, totalForms.val());
            });
            row.hide().insertBefore(template).fadeIn(300); // Animation
            $(totalForms).val(parseInt(totalForms.val(), 10) + 1);
            nextIndex += 1;
            if (maxForms.val() && (maxForms.val() - totalForms.val()) <= 0) {
                addButton.parent().hide();
            }
            toggleDeleteButtonVisibility(row.closest('.inline-group'));
            if (options.added) {
                options.added(row);
            }
            row.get(0).dispatchEvent(new CustomEvent("formset:added", {
                bubbles: true,
                detail: { formsetName: options.prefix }
            }));
            row.find('input:visible:first').focus(); // Accessibility: focus first input
        };

        const addInlineDeleteButton = function(row) {
            const deleteLink = `<a role="button" class="${options.deleteCssClass}" href="#" aria-label="Remove this form">${options.deleteText}</a>`;
            if (row.is("tr")) {
                row.children(":last").append(`<div>${deleteLink}</div>`);
            } else if (row.is("ul") || row.is("ol")) {
                row.append(`<li>${deleteLink}</li>`);
            } else {
                row.children(":first").append(`<span>${deleteLink}</span>`);
            }
            row.find(`a.${options.deleteCssClass}`).on('click', inlineDeleteHandler.bind(this));
        };

        const inlineDeleteHandler = function(e) {
            e.preventDefault();
            const deleteButton = $(e.target);
            const row = deleteButton.closest(`.${options.formCssClass}`);
            const inlineGroup = row.closest('.inline-group');
            const prevRow = row.prev();
            if (prevRow.length && prevRow.hasClass('row-form-errors')) {
                prevRow.remove();
            }
            row.fadeOut(300, () => {
                row.remove();
                nextIndex -= 1;
                if (options.removed) {
                    options.removed(row);
                }
                document.dispatchEvent(new CustomEvent("formset:removed", {
                    detail: { formsetName: options.prefix }
                }));
                const forms = $(`.${options.formCssClass}`);
                $(`#id_${options.prefix}-TOTAL_FORMS`).val(forms.length);
                if (!maxForms.val() || (maxForms.val() - forms.length) > 0) {
                    addButton.parent().show();
                }
                toggleDeleteButtonVisibility(inlineGroup);
                for (let i = 0, formCount = forms.length; i < formCount; i++) {
                    updateElementIndex($(forms).get(i), options.prefix, i);
                    $(forms.get(i)).find("*").each(function() {
                        updateElementIndex(this, options.prefix, i);
                    });
                }
            });
        };

        const toggleDeleteButtonVisibility = function(inlineGroup) {
            const deleteButtons = inlineGroup.find('.inline-deletelink');
            if (minForms.val() && (minForms.val() - totalForms.val()) >= 0) {
                deleteButtons.hide();
            } else {
                deleteButtons.show();
            }
        };

        $this.each(function(i) {
            $(this).not(`.${options.emptyCssClass}`).addClass(options.formCssClass);
        });

        $this.filter(`.${options.formCssClass}:not(.has_original):not(.${options.emptyCssClass})`).each(function() {
            addInlineDeleteButton($(this));
        });
        toggleDeleteButtonVisibility($this);

        addButton = options.addButton;
        addInlineAddButton();

        const showAddButton = !maxForms.val() || (maxForms.val() - totalForms.val()) > 0;
        if ($this.length && showAddButton) {
            addButton.parent().show();
        } else {
            addButton.parent().hide();
        }

        return this;
    };

    $.fn.formset.defaults = {
        prefix: "form",
        addText: "Add another",
        deleteText: "Remove",
        addCssClass: "add-row",
        deleteCssClass: "delete-row",
        emptyCssClass: "empty-row",
        formCssClass: "dynamic-form",
        added: null,
        removed: null,
        addButton: null
    };

    $.fn.tabularFormset = function(selector, options) {
        const $rows = $(this);

        const reinitDateTimeShortCuts = function() {
            if (typeof DateTimeShortcuts !== "undefined") {
                $(".datetimeshortcuts").remove();
                DateTimeShortcuts.init();
            }
        };

        const updateSelectFilter = function() {
            if (typeof SelectFilter !== 'undefined') {
                $('.selectfilter').each(function() {
                    SelectFilter.init(this.id, this.dataset.fieldName, false);
                });
                $('.selectfilterstacked').each(function() {
                    SelectFilter.init(this.id, this.dataset.fieldName, true);
                });
            }
        };

        const initPrepopulatedFields = function(row) {
            row.find('.prepopulated_field').each(function() {
                const field = $(this),
                      input = field.find('input, select, textarea'),
                      dependency_list = input.data('dependency_list') || [],
                      dependencies = [];
                $.each(dependency_list, function(i, field_name) {
                    dependencies.push(`#${row.find(`.field-${field_name}`).find('input, select, textarea').attr('id')}`);
                });
                if (dependencies.length) {
                    input.prepopulate(dependencies, input.attr('maxlength'));
                }
            });
        };

        $rows.formset({
            prefix: options.prefix,
            addText: options.addText,
            formCssClass: `dynamic-${options.prefix}`,
            deleteCssClass: "inline-deletelink",
            deleteText: options.deleteText,
            emptyCssClass: "empty-form",
            added: function(row) {
                initPrepopulatedFields(row);
                reinitDateTimeShortCuts();
                updateSelectFilter();
            },
            addButton: options.addButton
        });

        return $rows;
    };

    $.fn.stackedFormset = function(selector, options) {
        const $rows = $(this);

        const updateInlineLabel = function(row) {
            $(selector).find(".inline_label").each(function(i) {
                const count = i + 1;
                $(this).html($(this).html().replace(/#\d+/g, `#${count}`));
            });
        };

        const reinitDateTimeShortCuts = function() {
            if (typeof DateTimeShortcuts !== "undefined") {
                $(".datetimeshortcuts").remove();
                DateTimeShortcuts.init();
            }
        };

        const updateSelectFilter = function() {
            if (typeof SelectFilter !== "undefined") {
                $(".selectfilter").each(function() {
                    SelectFilter.init(this.id, this.dataset.fieldName, false);
                });
                $(".selectfilterstacked").each(function() {
                    SelectFilter.init(this.id, this.dataset.fieldName, true);
                });
            }
        };

        const initPrepopulatedFields = function(row) {
            row.find('.prepopulated_field').each(function() {
                const field = $(this),
                      input = field.find('input, select, textarea'),
                      dependency_list = input.data('dependency_list') || [],
                      dependencies = [];
                $.each(dependency_list, function(i, field_name) {
                    let field_element = row.find(`.form-row .field-${field_name}`);
                    if (!field_element.length) {
                        field_element = row.find(`.form-row.field-${field_name}`);
                    }
                    dependencies.push(`#${field_element.find('input, select, textarea').attr('id')}`);
                });
                if (dependencies.length) {
                    input.prepopulate(dependencies, input.attr('maxlength'));
                }
            });
        };

        $rows.formset({
            prefix: options.prefix,
            addText: options.addText,
            formCssClass: `dynamic-${options.prefix}`,
            deleteCssClass: "inline-deletelink",
            deleteText: options.deleteText,
            emptyCssClass: "empty-form",
            removed: updateInlineLabel,
            added: function(row) {
                initPrepopulatedFields(row);
                reinitDateTimeShortCuts();
                updateSelectFilter();
                updateInlineLabel(row);
            },
            addButton: options.addButton
        });

        return $rows;
    };

    $(document).ready(function() {
        $(".js-inline-admin-formset").each(function() {
            const data = $(this).data();
            const inlineOptions = data.inlineFormset;
            if (!inlineOptions) return; // Error handling: skip if no options
            let selector;
            switch(data.inlineType) {
                case "stacked":
                    selector = `${inlineOptions.name}-group .inline-related`;
                    $(selector).stackedFormset(selector, inlineOptions.options);
                    break;
                case "tabular":
                    selector = `${inlineOptions.name}-group .tabular.inline-related tbody:first > tr.form-row`;
                    $(selector).tabularFormset(selector, inlineOptions.options);
                    break;
                default:
                    console.warn(`Unknown inline type: ${data.inlineType}`);
            }
        });
    });
}
class Marty::DataImportView < Marty::CmFormPanel
  include Marty::Extras::Layout

  action :apply do |a|
    a.text    = I18n.t("data_import_view.import")
    a.tooltip = I18n.t("data_import_view.import")
    a.icon    = :database_go
  end

  js_configure do |c|

    c.set_result = <<-JS
      function(html) {
        var result = this.netzkeGetComponent('result');
        result.updateBodyHtml(html);
      }
      JS

    c.init_component = <<-JS
      function() {
        var me = this;
        me.callParent();
        var form = me.getForm();

        var comboname = form.findField('import_type');
        var textname  = form.findField('import_data');
        var importbutton = me.actions["apply"].items[0];

        comboname.on('select', function(combo, record) {
          textname.setValue("");
          me.netzkeGetComponent('result').updateBodyHtml('');
        });

        importbutton.on('click', function(t, e, ops) {
          me.netzkeGetComponent('result').updateBodyHtml('');
        });
      }
      JS
  end

  ######################################################################

  endpoint :netzke_submit do |params, this|
    data = ActiveSupport::JSON.decode(params[:data])

    import_data, import_type =
      data["import_data"] || "", data["import_type"] || ""

    return this.netzke_feedback("Must provide import data.") if
      import_data.empty?

    return this.netzke_feedback("Must provide import type") if
      import_type.empty?

    import_type_rec = Marty::ImportType.find_by_name(import_type)

    return this.netzke_feedback("Import type #{import_type} not found") unless
      import_type_rec

    return this.netzke_feedback("Insufficient permissions to run " +
                                "the data import") unless
      import_type_rec.allow_import?

    klass               = import_type_rec.get_model_class
    cleaner_function    = import_type_rec.cleaner_function
    validation_function = import_type_rec.validation_function

    begin
      res = Marty::DataImporter.do_import_summary(klass,
                                                  import_data,
                                                  'infinity',
                                                  cleaner_function,
                                                  validation_function,
                                                  )

      result = res.map { |k, v|
        case k
        when :clean  then "#{v} record(s) cleaned."
        when :same   then "#{v} record(s) unchanged."
        when :create then "#{v} record(s) created."
        when :update then "#{v} record(s) updated."
        when :blank  then "#{v} empty lines."
        end
      }

      this.set_result result.join("<br/>")
    rescue Marty::DataImporterError => exc
      result = [
                "Import failed on line(s): #{exc.lines.join(', ')}",
                "Error: #{exc.to_s}",
               ]

      this.set_result '<font color="red">' + result.join("<br/>") + "</font>"
    end
  end

  def configure(c)
    super

    c.title = I18n.t("data_import_view.import_data")
    c.items =
      [
       fieldset(I18n.t("data_import_view.select"),
                {
                  xtype:           :combo,
                  name:            "import_type",
                  store:           Marty::ImportType.all.map(&:name).sort,
                  max_width:       "350",
                  hide_label:      true,
                  force_selection: true,
                },
                {
                  name:         "import_data",
                  width:        "100%",
                  height:       300,
                  xtype:        :textareafield,
                  value:        "",
                  auto_scroll:  true,
                  hide_label:   true,
                  spellcheck:   false,
                  field_style: {
                    font_family: 'courier new',
                    font_size:   '12px'
                  },
                },
                min_width: 700,
                ),
       :result,
      ]
  end

  component :result do |c|
    c.klass       = Marty::CmPanel
    c.title       = I18n.t("data_import_view.results")
    c.html        = ""
    c.flex        = 1
    c.min_height  = 150
    c.auto_scroll = true
  end
end

DataImportView = Marty::DataImportView

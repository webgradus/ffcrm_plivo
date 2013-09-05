module FfcrmPlivo
    class PlivoViewHooks < FatFreeCRM::Callback::Base
        def javascript_includes(view, context = {})
            view.render(:partial => 'plivo/plivo_js')
        end
    end
end

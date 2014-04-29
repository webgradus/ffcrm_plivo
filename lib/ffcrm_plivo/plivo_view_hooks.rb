module FfcrmPlivo
    class PlivoViewHooks < FatFreeCRM::Callback::Base
        def javascript_includes(view, context = {})
            view.render(:partial => 'plivo/general_plivo')
        end
    end
end

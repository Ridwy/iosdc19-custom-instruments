;  page-id-validator.clp
;  ActionLogs
;
;  Created by Chiharu Nameki on 2019/09/07.
;  Copyright © 2019 Chiharu Nameki. All rights reserved.

(deftemplate current-page
    (slot page-id (type STRING))
)

(defrule MODELER::update-current-page
    (os-log (category "ActionLogs")
        (message$ "Type: " "view" ", Page ID: " ?page-id $?)
    )
    ?which <- (current-page)
    =>
    (modify ?which (page-id ?page-id))
)

(defrule RECORDER::record-page-id-error
    (os-log (category "ActionLogs") (time ?time)
        (message$ "Type: " "tap" ", Page ID: " ?page-id ", Element ID: " ?element-id)
    )
    (not (current-page (page-id ?page-id)))
    (current-page (page-id ?current-id))
    (table (table-id ?output) (side append))
    (table-attribute (table-id ?output) (has schema page-id-validator-narrative))
    =>
    (create-new-row ?output)
    (set-column time ?time)
    (set-column-narrative description "Page ID of tap %string% is %string%. It should be equal to current page ID %string%." ?element-id ?page-id ?current-id)
)

(deffacts MODELER::initial-page
    (current-page (page-id ""))
)

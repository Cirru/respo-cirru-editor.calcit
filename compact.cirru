
{} (:package |cirru-editor)
  :configs $ {} (:init-fn |cirru-editor.main/main!) (:reload-fn |cirru-editor.main/reload!) (:version |0.4.3)
    :modules $ [] |respo.calcit/ |lilac/ |memof/
  :entries $ {}
  :files $ {}
    |cirru-editor.comp.container $ {}
      :defs $ {}
        |comp-container $ quote
          defcomp comp-container (store)
            let
                states $ :states store
              div
                {} $ :style
                  {} (:position |absolute) (:width |100%) (:height |100%) (:display |flex) (:flex-direction |column)
                    :background-color $ hsl 0 0 0
                comp-editor states store on-update! on-command
        |on-command $ quote
          defn on-command (snapshot dispatch! e) (js/console.log "\"command" e)
        |on-update! $ quote
          defn on-update! (snapshot dispatch!) (dispatch! :save snapshot)
      :ns $ quote
        ns cirru-editor.comp.container $ :require
          [] respo.util.format :refer $ [] hsl
          [] respo.core :refer $ [] defcomp <> div span
          [] cirru-editor.comp.editor :refer $ [] comp-editor
    |cirru-editor.comp.editor $ {}
      :defs $ {}
        |common-styles $ quote
          def common-styles $ str |.cirru-expression{
            style->string $ .to-list style-expression
            , "|} .cirru-token{"
              style->string $ .to-list style-token
              , |}
        |comp-editor $ quote
          defcomp comp-editor (states snapshot on-update! on-command)
            div
              {} $ :style style-editor
              style $ {} (:innerHTML common-styles)
              div
                {} $ :style style-box
                comp-expression states (:tree snapshot) (handle-update snapshot on-update!) ([]) 0 false (:focus snapshot) (handle-command on-command snapshot) true false
              ; comp-inspect snapshot $ {} (:bottom 0) (:left 0)
        |handle-command $ quote
          defn handle-command (on-command snapshot)
            fn (e dispatch!) (on-command snapshot dispatch! e)
        |handle-update $ quote
          defn handle-update (snapshot on-update!)
            fn (op op-data dispatch!)
              on-update! (cirru-edit snapshot op op-data) dispatch!
        |style-box $ quote
          def style-box $ {} (:flex 1) (:overflow-y |auto) (:padding "|100px 0 200px 0")
        |style-editor $ quote
          def style-editor $ {} (:padding "|8px 8px 8px 8px") (:min-height |200px) (:display |flex) (:flex-direction |column) (:position |relative) (:flex 1)
      :ns $ quote
        ns cirru-editor.comp.editor $ :require
          hsl.core :refer $ hsl
          respo.core :refer $ defcomp <> div style span
          respo.comp.inspect :refer $ comp-inspect
          respo.comp.space :refer $ =<
          cirru-editor.core :refer $ cirru-edit
          cirru-editor.comp.expression :refer $ comp-expression style-expression
          cirru-editor.comp.token :refer $ style-token
          respo.render.html :refer $ style->string
    |cirru-editor.comp.expression $ {}
      :defs $ {}
        |comp-expression $ quote
          defcomp comp-expression (states expression modify! coord level tail? focus on-command head? inline?)
            let
                exp-size $ count expression
                cursor $ :cursor states
                state $ either (:data states) false
              if state
                div
                  {} (:style style-folded)
                    :on-click $ fn (e dispatch!)
                      dispatch! cursor $ not state
                    :on-keydown $ on-keydown state modify! coord on-command cursor
                  <> (first expression) nil
                list->
                  {} (:tab-index 0)
                    :class-name $ if (= coord focus) "|editor-focused cirru-expression" |cirru-expression
                    :style $ merge ({}) (if inline? style-inline)
                      if
                        and tail? (not head?) (pos? level)
                        , style-tail
                      if (= coord focus)
                        {} $ :border-color (hsl 0 0 100 0.6)
                    :on-click $ on-click modify! coord focus
                    :on-keydown $ on-keydown state modify! coord on-command cursor
                  apply-args
                      []
                      , 0 expression nil
                    fn (acc idx expr prev-kind)
                      if (empty? expr) acc $ let
                          item $ first expr
                          kind $ if (string? item) :leaf
                            if
                              and
                                <= (count item) 1
                                string? $ first item
                              , :leaf $ case-default prev-kind :expr (:expr :expr)
                                :inline-expr $ if
                                  and
                                    <= (count item) 2
                                    every? item string?
                                  , :inline-expr :expr
                                :leaf $ if
                                  and
                                    <= (count item) 6
                                    every? item string?
                                  , :inline-expr :expr
                                nil $ if
                                  and
                                    <= (count item) 6
                                    every? item string?
                                  , :inline-expr :expr
                          pair $ [] idx
                            let
                                child-coord $ conj coord idx
                                child-focus $ if (coord-contains? focus child-coord) focus nil
                                child-head? $ zero? idx
                              if (string? item) (comp-token item modify! child-coord child-focus on-command child-head?)
                                comp-expression (>> states idx) item modify! child-coord (inc level)
                                  and (not tail?)
                                    = (dec exp-size) idx
                                    = prev-kind :leaf
                                  , child-focus on-command child-head? $ or (= kind :inline-expr) (= kind :leaf)
                          next-acc $ conj acc pair
                        ; println "\"kinds:" prev-kind kind "\" at " item
                        recur next-acc (inc idx) (rest expr) kind
        |on-click $ quote
          defn on-click (modify! coord focus)
            fn (e dispatch!)
              if (not= coord focus) (modify! :focus-to coord dispatch!)
        |on-keydown $ quote
          defn on-keydown (state modify! coord on-command cursor)
            fn (e dispatch!)
              let
                  code $ :key-code e
                  event $ :original-event e
                  shift? $ .-shiftKey event
                  command? $ or (.-metaKey event) (.-ctrlKey event)
                cond
                    = code keycode/space
                    do (.!preventDefault event)
                      if shift? (modify! :before-token coord dispatch!) (modify! :after-token coord dispatch!)
                  (= code keycode/tab)
                    do (.!preventDefault event)
                      if shift? (modify! :unfold-expression coord dispatch!) (modify! :fold-node coord dispatch!)
                  (= code keycode/enter)
                    if command?
                      if shift? (modify! :append-expression coord dispatch!) (modify! :prepend-expression coord dispatch!)
                      if shift? (modify! :before-expression coord dispatch!) (modify! :after-expression coord dispatch!)
                  (= code keycode/backspace)
                    do (.!preventDefault event) (modify! :remove-node coord dispatch!)
                  (= code keycode/left)
                    do (.!preventDefault event) (modify! :node-left coord dispatch!)
                  (= code keycode/right)
                    do (.!preventDefault event) (modify! :node-right coord dispatch!)
                  (= code keycode/up)
                    do (.!preventDefault event) (modify! :node-up coord dispatch!)
                  (= code keycode/down)
                    do (.!preventDefault event) (modify! :expression-down coord dispatch!)
                  (and command? (= code keycode/key-b))
                    do (.!preventDefault event) (modify! :duplicate-expression coord dispatch!)
                  (and command? (= code keycode/key-c))
                    modify! :command-copy coord dispatch!
                  (and command? (= code keycode/key-x))
                    modify! :command-cut coord dispatch!
                  (and command? (= code keycode/key-v))
                    modify! :command-paste coord dispatch!
                  (and command? shift? (= code keycode/key-f))
                    dispatch! cursor $ not state
                  true $ if command? (on-command e dispatch!) nil
        |style-expression $ quote
          def style-expression $ {} (:border-style |solid) (:outline |none) (:padding-left 8) (:padding-right 0) (:padding-top 2) (:padding-bottom 0) (:margin-left 12) (:margin-right 0) (:margin-top 0) (:margin-bottom 4) (:border-width "|0 0 0 1px") (:min-height |26px) (:min-width |16px) (:vertical-align |top) (:box-sizing |border-box) (:border-radius "\"8px")
            :border-color $ hsl 0 0 32 0.9
        |style-folded $ quote
          def style-folded $ {} (:display |inline-block)
            :color $ hsl 180 80 60
            :font-family "|Source Code Pro,Menlo,monospace"
            :font-size |15px
            :outline |none
            :border-width |1px
            :border-style |solid
            :border-color $ hsl 0 0 100 0.5
            :padding-left 16
            :padding-right 16
            :vertical-align |top
            :line-height |27px
            :border-radius |16px
            :cursor |pointer
            :margin-bottom |4px
        |style-inline $ quote
          def style-inline $ {} (:display |inline-block) (:border-width "|0 0 1px 0") (:padding-left 7) (:padding-right 7) (:padding-bottom 2) (:margin-left 8) (:margin-right 4) (:text-align |center)
            :background-color $ hsl 200 80 80 0
        |style-tail $ quote
          def style-tail $ {} (:display |inline-block) (:border-width "|0 0 0 1px")
            :background-color $ hsl 0 80 80 0
      :ns $ quote
        ns cirru-editor.comp.expression $ :require
          respo.util.format :refer $ hsl
          respo.core :refer $ defcomp list-> >> <> div span
          respo.comp.space :refer $ =<
          respo.comp.inspect :refer $ comp-inspect
          cirru-editor.comp.token :refer $ comp-token
          cirru-editor.util.detect :refer $ coord-contains? shallow? deep?
          cirru-editor.util.keycode :as keycode
          cirru-editor.util :refer $ pos? zero?
    |cirru-editor.comp.token $ {}
      :defs $ {}
        |comp-token $ quote
          defcomp comp-token (token modify! coord focus on-command head?)
            input $ {} (:value token) (:spellcheck false)
              :class-name $ if (= coord focus) "|editor-focused cirru-token" |cirru-token
              :style $ merge ({})
                {} $ :width
                  str
                    + 8 $ text-width token 15 (:font-family style-token)
                    , |px
                cond
                    contains? (#{} "\"true" "\"false") token
                    {} $ :color "\"rgb(119, 102, 204)"
                  (contains? (#{} "\"nil") token)
                    {} $ :color "\"rgb(163, 41, 143)"
                  (= "\"#\"" (.slice token 0 2))
                    {} $ :color (hsl 300 60 45)
                  (contains? (#{} "\"\"" "\"|") (.slice token 0 1))
                    {} $ :color "\"rgb(75, 210, 75)"
                  (contains? (#{} "\":") (.slice token 0 1))
                    {} $ :color "\"rgb(136, 136, 191)"
                  (.!test pattern-number token)
                    {} $ :color "\"rgb(173, 31, 31)"
                  head? $ {}
                    :color $ hsl 40 80 60 0.9
                  true nil
                if
                  or (has-blank? token)
                    zero? $ count token
                  {} $ :background-color (hsl 0 0 100 0.16)
              :on $ {}
                :input $ on-input modify! coord
                :keydown $ on-keydown modify! coord token on-command
                :click $ on-click modify! coord focus
        |on-click $ quote
          defn on-click (modify! coord focus)
            fn (e dispatch!)
              if (not= coord focus) (modify! :focus-to coord dispatch!)
        |on-input $ quote
          defn on-input (modify! coord)
            fn (e dispatch!)
              modify! :update-token
                [] coord $ :value e
                , dispatch!
        |on-keydown $ quote
          defn on-keydown (modify! coord token on-command)
            fn (e dispatch!)
              let
                  code $ :key-code e
                  event $ :original-event e
                  shift? $ .-shiftKey event
                  command? $ or (.-metaKey event) (.-ctrlKey event)
                  target $ .-target event
                  at-start? $ zero? (.-selectionStart target)
                  at-end? $ = (count token) (.-selectionEnd target)
                  thin-cursor? $ = (.-selectionStart target) (.-selectionEnd target)
                cond
                    and (= code keycode/space) (not shift?)
                    do (.!preventDefault event) (modify! :after-token coord dispatch!)
                  (= code keycode/tab)
                    do (.!preventDefault event)
                      if shift? (modify! :unfold-token coord dispatch!) (modify! :fold-node coord dispatch!)
                  (= code keycode/enter)
                    if shift? (modify! :before-token coord dispatch!) (modify! :after-token coord dispatch!)
                  (= code keycode/backspace)
                    if (= token |)
                      do (modify! :remove-node coord dispatch!) (.!preventDefault event)
                  (= code keycode/up)
                    do (.!preventDefault event) (modify! :node-up coord dispatch!)
                  (and thin-cursor? at-start? (= code keycode/left))
                    do (.!preventDefault event) (modify! :node-left coord dispatch!)
                  (and thin-cursor? at-end? (= code keycode/right))
                    do (.!preventDefault event) (modify! :node-right coord dispatch!)
                  (and shift? command? (= code keycode/key-v))
                    do (.!preventDefault event) (modify! :command-paste coord dispatch!)
                  true $ if command? (on-command e dispatch!) nil
        |pattern-number $ quote
          def pattern-number $ new js/RegExp "\"-?[\\d\\.]+"
        |style-token $ quote
          def style-token $ {} (:border |none) (:font-size |15px) (:line-height |24px) (:font-family "|Source Code Pro,Menlo,monospace") (:padding "|0 2px") (:margin-left 2) (:margin-right 2) (:outline |none) (:max-width |320px)
            :background-color $ hsl 0 0 100 0
            :color $ hsl 200 12 67 0.9
            :text-align |center
      :ns $ quote
        ns cirru-editor.comp.token $ :require
          respo.util.format :refer $ hsl
          respo.core :refer $ defcomp <> div input
          cirru-editor.util.measure :refer $ text-width
          cirru-editor.util.detect :refer $ has-blank?
          cirru-editor.util.keycode :as keycode
          cirru-editor.util :refer $ zero?
    |cirru-editor.config $ {}
      :defs $ {}
        |dev? $ quote
          def dev? $ = "\"dev" (get-env "\"mode")
        |site $ quote
          def site $ {} (:title "\"Cirru Editor") (:icon "\"http://cdn.tiye.me/logo/cirru.png") (:storage-key "\"respo-cirru-editor")
      :ns $ quote (ns cirru-editor.config)
    |cirru-editor.core $ {}
      :defs $ {}
        |cirru-edit $ quote
          defn cirru-edit (snapshot op op-data) (; println :update-state op op-data)
            let
                handler $ case-default op
                  do (println "\"Unknown op:" op) default-handler
                  :update-token tree/update-token
                  :after-token tree/after-token
                  :fold-node tree/fold-node
                  :unfold-expression tree/unfold-expression
                  :unfold-token tree/unfold-token
                  :before-expression tree/before-expression
                  :after-expression tree/after-expression
                  :prepend-expression tree/prepend-expression
                  :append-expression tree/append-expression
                  :before-token tree/before-token
                  :remove-node tree/remove-node
                  :focus-to focus/focus-to
                  :node-up focus/node-up
                  :expression-down focus/expression-down
                  :node-left focus/node-left
                  :node-right focus/node-right
                  :command-copy command/copy
                  :command-cut command/cut
                  :command-paste command/paste
                  :tree-reset tree/tree-reset
                  :duplicate-expression tree/duplicate-expression
              handler snapshot op-data
        |default-handler $ quote
          defn default-handler (snapshot op-data) snapshot
      :ns $ quote
        ns cirru-editor.core $ :require (cirru-editor.modifier.tree :as tree) (cirru-editor.modifier.focus :as focus) (cirru-editor.modifier.command :as command)
    |cirru-editor.main $ {}
      :defs $ {}
        |*store $ quote (defatom *store schema/store)
        |*touched $ quote (defatom *touched false)
        |dispatch! $ quote
          defn dispatch! (op op-data) (; println |dispatch: op op-data)
            case-default op nil
              :save $ reset! *store op-data
              :states $ reset! *store (update-states @*store op-data)
            reset! *touched true
        |main! $ quote
          defn main! ()
            if config/dev? $ load-console-formatter!
            println "\"Running mode:" $ if config/dev? "\"dev" "\"release"
            render-app!
            add-watch *store :changes $ fn (s p) (render-app!)
            println "|app started!"
        |mount-target $ quote
          def mount-target $ js/document.querySelector |.app
        |reload! $ quote
          defn reload! () $ if (nil? build-errors)
            do (remove-watch *store :changes) (clear-cache!)
              add-watch *store :changes $ fn (s p) (render-app!)
              render-app!
              hud! "\"ok~" "\"Ok"
            hud! "\"error" build-errors
        |render-app! $ quote
          defn render-app! ()
            render! mount-target (comp-container @*store) dispatch!
            if @*touched $ do (reset! *touched false) (println "|changing focus") (focus!)
      :ns $ quote
        ns cirru-editor.main $ :require
          respo.core :refer $ render! clear-cache! realize-ssr!
          respo.cursor :refer $ update-states
          cirru-editor.comp.container :refer $ comp-container
          cljs.reader :refer $ read-string
          cirru-editor.util.dom :refer $ focus!
          cirru-editor.schema :as schema
          cirru-editor.config :as config
          "\"./calcit.build-errors" :default build-errors
          "\"bottom-tip" :default hud!
    |cirru-editor.modifier.command $ {}
      :defs $ {}
        |copy $ quote
          defn copy (snapshot op-data)
            let
                coord op-data
                expression $ get-in snapshot
                  concat ([] :tree) coord
              -> snapshot $ assoc :clipboard expression
        |cut $ quote
          defn cut (snapshot op-data)
            let
                coord op-data
                expression $ get-in snapshot
                  concat ([] :tree) coord
                position $ last coord
              -> snapshot
                update-in
                  concat ([] :tree) (butlast coord)
                  fn (parent)
                    if (zero? position) ([]) (.slice parent 1)
                    cond
                        = 1 $ count parent
                        []
                      (zero? position) (.slice parent 1)
                      (= position (dec (count parent)))
                        butlast parent
                      true $ concat (.slice parent 0 position)
                        .slice parent $ inc position
                assoc :focus $ if (zero? position) (butlast coord)
                  conj (butlast coord) (dec position)
                assoc :clipboard expression
        |paste $ quote
          defn paste (snapshot op-data)
            let
                coord op-data
              -> snapshot $ assoc-in (prepend coord :tree) (:clipboard snapshot)
      :ns $ quote
        ns cirru-editor.modifier.command $ :require
          cirru-editor.util :refer $ zero?
    |cirru-editor.modifier.focus $ {}
      :defs $ {}
        |expression-down $ quote
          defn expression-down (snapshot coord)
            let
                expression $ get-in snapshot (prepend coord :tree)
              -> snapshot $ assoc :focus
                if
                  pos? $ count expression
                  conj coord 0
                  , coord
        |focus-to $ quote
          defn focus-to (snapshot op-data)
            let
                coord op-data
              assoc snapshot :focus coord
        |node-left $ quote
          defn node-left (snapshot focus)
            -> snapshot $ assoc :focus
              let
                  position $ last focus
                conj (butlast focus)
                  if (pos? position) (dec position) position
        |node-right $ quote
          defn node-right (snapshot focus)
            -> snapshot $ assoc :focus
              let
                  position $ last focus
                  parent $ get-in snapshot
                    concat ([] :tree) (butlast focus)
                conj (butlast focus)
                  if
                    < position $ dec (count parent)
                    inc position
                    , position
        |node-up $ quote
          defn node-up (snapshot focus)
            -> snapshot $ assoc :focus
              if
                pos? $ count focus
                .slice focus 0 $ dec (count focus)
                , focus
      :ns $ quote
        ns cirru-editor.modifier.focus $ :require
          cirru-editor.util :refer $ pos?
    |cirru-editor.modifier.tree $ {}
      :defs $ {}
        |after-expression $ quote
          defn after-expression (snapshot op-data)
            let
                coord op-data
              if
                pos? $ count coord
                -> snapshot
                  update-in
                    cons :tree $ butlast coord
                    fn (parent)
                      let
                          position $ last coord
                        cond
                            = position $ dec (count parent)
                            conj parent $ [] |
                          :else $ concat
                            subvec parent 0 $ inc position
                            [] $ [] |
                            subvec parent $ inc position
                  assoc :focus $ conj (butlast coord)
                    inc $ last coord
                    , 0
                if
                  = (:tree snapshot) ([])
                  -> snapshot
                    assoc :focus $ [] 0
                    assoc :tree $ [] |
                  , snapshot
        |after-token $ quote
          defn after-token (snapshot op-data)
            let
                coord op-data
              if
                not $ empty? coord
                -> snapshot
                  update-in
                    cons :tree $ butlast coord
                    fn (expression)
                      if
                        = (last coord)
                          dec $ count expression
                        conj expression |
                        concat
                          subvec expression 0 $ inc (last coord)
                          [] |
                          subvec expression $ inc (last coord)
                  assoc :focus $ conj (butlast coord)
                    inc $ last coord
                if
                  = (:tree snapshot) ([])
                  -> snapshot
                    assoc :focus $ [] 0
                    assoc :tree $ [] |
                  , snapshot
        |append-expression $ quote
          defn append-expression (snapshot op-data)
            let
                coord op-data
                expression $ get-in snapshot (cons :tree coord)
              -> snapshot
                update-in (cons :tree coord)
                  fn (parent) (conj parent |)
                assoc :focus $ conj coord (count expression)
        |before-expression $ quote
          defn before-expression (snapshot op-data)
            let
                coord op-data
              -> snapshot
                update-in
                  cons :tree $ butlast coord
                  fn (parent)
                    let
                        position $ last coord
                      cond
                          zero? position
                          cons ([] |) parent
                        true $ concat (subvec parent 0 position)
                          [] $ [] |
                          subvec parent position
                assoc :focus $ conj coord 0
        |before-token $ quote
          defn before-token (snapshot op-data)
            let
                coord op-data
              -> snapshot $ update-in
                cons :tree $ butlast coord
                fn (parent)
                  let
                      position $ last coord
                    cond
                        zero? position
                        cons | parent
                      true $ concat (&list:slice parent 0 position) ([] |) (&list:slice parent position)
        |duplicate-expression $ quote
          defn duplicate-expression (snapshot focus)
            if (empty? focus) snapshot $ -> snapshot
              assoc :focus $ if
                = 1 $ count focus
                [] $ inc (first focus)
                conj (butlast focus)
                  inc $ last focus
              update :tree $ fn (tree)
                if
                  = 1 $ count focus
                  let
                      pos $ first focus
                    concat
                      .slice tree 0 $ inc pos
                      .slice tree pos
                  update-in tree (butlast focus)
                    fn (parent)
                      let
                          pos $ last focus
                        concat
                          .slice parent 0 $ inc pos
                          .slice parent pos
        |fold-node $ quote
          defn fold-node (snapshot op-data)
            let
                coord op-data
              -> snapshot
                update-in (cons :tree coord)
                  fn (node) ([] node)
                assoc :focus $ conj coord 0
        |prepend-expression $ quote
          defn prepend-expression (snapshot op-data)
            let
                coord op-data
              -> snapshot
                update-in (cons :tree coord)
                  fn (parent) (cons | parent)
                assoc :focus $ conj coord 0
        |remove-node $ quote
          defn remove-node (snapshot op-data)
            let
                coord op-data
              if
                pos? $ count coord
                -> snapshot
                  update-in
                    prepend (butlast coord) :tree
                    fn (parent)
                      let
                          position $ last coord
                        cond
                            = 1 $ count parent
                            []
                          (zero? position) (rest parent)
                          (= position (dec (count parent)))
                            butlast parent
                          true $ concat (.slice parent 0 position)
                            .slice parent $ inc position
                  assoc :focus $ let
                      position $ last coord
                    if (zero? position) (butlast coord)
                      concat (butlast coord)
                        [] $ dec position
                , snapshot
        |tree-reset $ quote
          defn tree-reset (snapshot op-data)
            let
                tree op-data
              -> snapshot (assoc :tree tree)
                assoc :focus $ []
        |unfold-expression $ quote
          defn unfold-expression (snapshot op-data)
            let
                coord op-data
              cond
                  > (count coord) 1
                  -> snapshot
                    update :tree $ fn (tree)
                      let
                          expression $ get-in tree coord
                          position $ last coord
                        update-in tree (butlast coord)
                          fn (parent)
                            cond
                                zero? position
                                concat expression $ rest parent
                              (= position (dec (count parent)))
                                concat (butlast parent) expression
                              true $ concat (subvec parent 0 position) expression
                                subvec parent $ inc position
                    assoc :focus $ butlast coord
                (= 1 (count coord))
                  -> snapshot $ update :tree
                    fn (parent)
                      let
                          expression $ get-in parent coord
                          position $ last coord
                        cond
                            zero? position
                            concat expression $ rest parent
                          (= position (dec (count parent)))
                            concat (butlast parent) expression
                          :else $ concat (subvec parent 0 position) expression
                            subvec parent $ inc position
                :else snapshot
        |unfold-token $ quote
          defn unfold-token (snapshot op-data)
            let
                tree $ :tree snapshot
                focus op-data
              if (empty? focus) snapshot $ let
                  parent-coord $ butlast focus
                  parent $ get-in tree parent-coord
                if
                  = (count parent) 1
                  -> snapshot
                    update-in (cons :tree parent-coord) first
                    assoc :focus parent-coord
                  , snapshot
        |update-token $ quote
          defn update-token (snapshot op-data)
            let-sugar
                  [] coord new-token
                  , op-data
              -> snapshot $ assoc-in (cons :tree coord) new-token
      :ns $ quote
        ns cirru-editor.modifier.tree $ :require
          cirru-editor.util :refer $ zero? pos? subvec cons
    |cirru-editor.schema $ {}
      :defs $ {}
        |store $ quote
          def store $ {}
            :states $ {}
            :tree $ [] "\"defn" "\"get-something" ([]) ([] "\"[]" "\"1" "\"-1" "\"\"2" "\"true" "\"nil" "\":k")
            :focus $ []
            :clipboard $ []
      :ns $ quote (ns cirru-editor.schema)
    |cirru-editor.util $ {}
      :defs $ {}
        |cons $ quote
          defn cons (y xs) (prepend xs y)
        |pos? $ quote
          defn pos? (x) (&> x 0)
        |subvec $ quote (def subvec &list:slice)
        |zero? $ quote
          defn zero? (x) (&= x 0)
      :ns $ quote (ns cirru-editor.util)
    |cirru-editor.util.detect $ {}
      :defs $ {}
        |coord-contains? $ quote
          defn coord-contains? (a b)
            if (nil? a) false $ if (empty? b) true
              if (empty? a) false $ if
                = (first a) (first b)
                recur (rest a) (rest b)
                , false
        |deep? $ quote
          defn deep? (expression)
            some
              fn (item) (vector? item)
              , expression
        |has-blank? $ quote
          defn has-blank? (x) (includes? x "| ")
        |shallow? $ quote
          defn shallow? (expression)
            every?
              fn (item) (string? item)
              , expression
      :ns $ quote (ns cirru-editor.util.detect)
    |cirru-editor.util.dom $ {}
      :defs $ {}
        |focus! $ quote
          defn focus! () $ js/requestAnimationFrame
            fn (timestap)
              let
                  editor-focus $ js/document.querySelector |.editor-focused
                  current-focus js/document.activeElement
                if (some? editor-focus)
                  if
                    not $ identical? editor-focus current-focus
                    .!focus editor-focus
                    , nil
                  println "|Editor warning: cannot find focus target."
      :ns $ quote (ns cirru-editor.util.dom)
    |cirru-editor.util.keycode $ {}
      :defs $ {}
        |backspace $ quote (def backspace 8)
        |down $ quote (def down 40)
        |enter $ quote (def enter 13)
        |key-b $ quote (def key-b 66)
        |key-c $ quote (def key-c 67)
        |key-f $ quote (def key-f 70)
        |key-s $ quote (def key-s 83)
        |key-v $ quote (def key-v 86)
        |key-x $ quote (def key-x 88)
        |left $ quote (def left 37)
        |right $ quote (def right 39)
        |space $ quote (def space 32)
        |tab $ quote (def tab 9)
        |up $ quote (def up 38)
      :ns $ quote (ns cirru-editor.util.keycode)
    |cirru-editor.util.measure $ {}
      :defs $ {}
        |*ctx $ quote
          defatom *ctx $ if (exists? js/document)
            .!getContext (js/document.createElement |canvas) |2d
            , nil
        |text-width $ quote
          defn text-width (content font-size font-family)
            let
                ctx @*ctx
              if (some? ctx)
                do
                  set! (.-font ctx) (str font-size "|px " font-family)
                  .-width $ .measureText ctx content
                + 4 $ * (count content) 9
      :ns $ quote (ns cirru-editor.util.measure)

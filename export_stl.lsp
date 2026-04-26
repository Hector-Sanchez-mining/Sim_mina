;; ============================================================
;;  EXPORT-STL-BY-LAYER  v2  (export_stl.lsp)
;;
;;  Agrupa todos los 3DSOLID del dibujo por layer y exporta
;;  un archivo .STL por layer usando el nombre del layer.
;;  Al terminar genera models.json con listado + unidades.
;;
;;  Comando : EXPORTSTL
;;  AutoCAD 2020-2026  |  Héctor
;; ============================================================

(vl-load-com)

(defun c:EXPORTSTL ( / outDir ss i ent layName layTable
                       modelList jsonPath fh origLayers *error* )

  (defun *error* ( msg )
    (setvar "FILEDIA" 1)
    (if (not (wcmatch msg "Function cancelled,quitting"))
      (princ (strcat "\nError: " msg))
    )
    (princ)
  )

  (setvar "FILEDIA" 0)

  ;; ── 1. Carpeta de salida ─────────────────────────────────
  (setq outDir (stl:browse-for-folder "Selecciona carpeta de destino para los STL"))
  (if (null outDir)
    (progn (princ "\nCancelado.") (setvar "FILEDIA" 1) (exit))
  )
  (if (not (wcmatch (substr outDir (strlen outDir) 1) "[/\\]"))
    (setq outDir (strcat outDir "\\"))
  )

  ;; ── 2. Buscar todos los 3DSOLID ──────────────────────────
  (setq ss (ssget "_X" '((0 . "3DSOLID"))))
  (if (null ss)
    (progn (princ "\nNo se encontraron sólidos 3D en el dibujo.") (exit))
  )
  (princ (strcat "\n" (itoa (sslength ss)) " sólido(s) encontrado(s)."))

  ;; ── 3. Agrupar por layer ─────────────────────────────────
  (setq layTable (list))
  (setq i 0)
  (repeat (sslength ss)
    (setq ent     (ssname ss i)
          layName (cdr (assoc 8 (entget ent))))
    (setq layTable (stl:push-assoc layTable layName ent))
    (setq i (1+ i))
  )
  (princ (strcat "\n" (itoa (length layTable)) " layer(s) con sólidos."))

  ;; ── 4. Snapshot de layers ────────────────────────────────
  (setq origLayers (stl:snapshot-layers))

  ;; ── 5. Exportar un STL por layer ─────────────────────────
  (setq modelList (list))

  (foreach pair layTable
    (setq layName (car pair))
    (princ (strcat "\n  → Exportando [" layName "] ..."))
    (stl:isolate-layer layName)
    (setq ss (ssadd))
    (foreach ent (cdr pair) (ssadd ent ss))
    (setq stlPath (strcat outDir layName ".stl"))
    (stl:write-stl ss stlPath)
    (if (findfile stlPath)
      (setq modelList (append modelList (list (strcat layName ".stl"))))
      (princ (strcat "\n  [!] Omitido (no se generó): " layName))
    )
  )

  ;; ── 6. Detectar unidades del dibujo ──────────────────────
  ;; INSUNITS: 4=mm, 5=cm, 6=m, 2=ft, 1=in, 0=sin unidades
  (setq insUnits (getvar "INSUNITS"))
  (setq unitsStr
    (cond
      ((= insUnits 4) "mm")
      ((= insUnits 5) "cm")
      ((= insUnits 6) "m")
      ((= insUnits 2) "ft")
      ((= insUnits 1) "in")
      (t              "mm")   ; default: asumir mm para minería
    )
  )

  ;; ── 7. Escribir models.json ───────────────────────────────
  (setq jsonPath (strcat outDir "models.json"))
  (setq fh (open jsonPath "w"))
  (write-line "{" fh)
  (write-line (strcat "  \"units\": \"" unitsStr "\",") fh)
  (write-line "  \"models\": [" fh)
  (setq i 0)
  (foreach name modelList
    (setq i (1+ i))
    (if (= i (length modelList))
      (write-line (strcat "    \"" name "\"") fh)
      (write-line (strcat "    \"" name "\",") fh)
    )
  )
  (write-line "  ]" fh)
  (write-line "}" fh)
  (close fh)

  ;; ── 8. Restaurar layers ──────────────────────────────────
  (stl:restore-layers origLayers)

  (setvar "FILEDIA" 1)
  (princ (strcat "\n\n✓ " (itoa (length modelList))
                 " STL exportado(s) en: " outDir))
  (princ (strcat "\n✓ models.json generado  [units: " unitsStr "]"))
  (princ)
)


;; ============================================================
;;  Helpers
;; ============================================================

(defun stl:push-assoc ( alist key val / pair )
  (setq pair (assoc key alist))
  (if pair
    (subst (cons key (append (cdr pair) (list val))) pair alist)
    (append alist (list (cons key (list val))))
  )
)

(defun stl:snapshot-layers ( / doc snap lay )
  (setq doc  (vla-get-ActiveDocument (vlax-get-acad-object))
        snap (list))
  (vlax-for lay (vla-get-Layers doc)
    (setq snap
      (cons (list (vla-get-Name    lay)
                  (vla-get-LayerOn lay)
                  (vla-get-Freeze  lay))
            snap))
  )
  snap
)

(defun stl:isolate-layer ( targetLay / doc curLay lay name )
  (setq doc    (vla-get-ActiveDocument (vlax-get-acad-object))
        curLay (getvar "CLAYER"))
  (vlax-for lay (vla-get-Layers doc)
    (setq name (vla-get-Name lay))
    (cond
      ((= name targetLay)
       (vla-put-LayerOn lay :vlax-true)
       (vla-put-Freeze  lay :vlax-false))
      ((or (= name "0") (= name curLay)) nil)
      (t
       (vl-catch-all-apply 'vla-put-LayerOn (list lay :vlax-false)))
    )
  )
)

(defun stl:restore-layers ( snap / doc lay name entry )
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (vlax-for lay (vla-get-Layers doc)
    (setq name  (vla-get-Name lay)
          entry (assoc name snap))
    (if entry
      (progn
        (vl-catch-all-apply 'vla-put-LayerOn (list lay (cadr  entry)))
        (vl-catch-all-apply 'vla-put-Freeze  (list lay (caddr entry)))
      )
    )
  )
)

(defun stl:write-stl ( ss stlPath / )
  (if (findfile stlPath) (vl-file-delete stlPath))
  ;; Intentar con prompt estándar (binario = Y)
  (vl-catch-all-apply
    'command (list "_.STLOUT" ss "" "Y" stlPath)
  )
  ;; Fallback: sin flag de binario (algunas versiones no lo piden)
  (if (not (findfile stlPath))
    (vl-catch-all-apply
      'command (list "_.STLOUT" ss "" stlPath)
    )
  )
  (if (findfile stlPath)
    (princ " [OK]")
    (princ " [!] no se generó")
  )
)

(defun stl:browse-for-folder ( titulo / shell folder item path )
  (setq shell  (vla-GetInterfaceObject
                 (vlax-get-acad-object)
                 "Shell.Application")
        folder (vlax-invoke shell 'BrowseForFolder
                  0 titulo 0 (getvar "DWGPREFIX"))
  )
  (if folder
    (progn
      (setq item (vlax-get-property folder 'Self)
            path (vlax-get-property item  'Path))
      (vlax-release-object item)
      (vlax-release-object folder)
      (vlax-release-object shell)
      path
    )
    (progn
      (vlax-release-object shell)
      nil
    )
  )
)

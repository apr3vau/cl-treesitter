(defpackage :treesitter
  (:use :cl :cffi :treesitter/bindings)
  (:export
   ;; types
   :language
   :parser
   :point
   :node
   :tree
   :cursor
   ;; parser
   :make-parser
   :parser-language
   :parser-timeout
   :parser-parse-string
   :parser-reset
   ;; tree
   :tree-root-node
   :tree-language
   ;; node
   :node-type
   :node-symbol
   :node-language
   :node-grammar-type
   :node-grammar-symbol
   :node-start-byte
   :node-end-byte
   :node-start-point
   :node-end-point
   :node-string
   :node-null-p
   :node-named-p
   :node-missing-p
   :node-extra-p
   :node-has-changes
   :node-has-error
   :node-error-p
   :node-parent
   :node-child
   :node-child-count
   :node-next-sibling
   :node-prev-sibling
   :node-eq
   ;; cursor
   :make-cursor
   :cursor-reset
   :cursor-node
   :cursor-field-name
   :cursor-field-id
   :cursor-goto-parent
   :cursor-goto-next-sibling
   :cursor-goto-prev-sibling
   :cursor-goto-first-child
   :cursor-goto-last-child
   :cursor-goto-descendant
   :cursor-descendant-index
   :cursor-depth
   :cursor-goto-first-child-for-byte
   :cursor-goto-first-child-for-point
   ))
(in-package :treesitter)

(defclass foreign-object ()
  ((pointer
    :initarg :pointer
    :initform (error "Must provide :pointer")
    :accessor pointer)
   (free
    :initarg :free
    :initform #'foreign-free
    :accessor free)))

(defmethod initialize-instance :after ((self foreign-object) &key &allow-other-keys)
  (let ((pointer (slot-value self 'pointer))
        (free (slot-value self 'free)))
    (tg:finalize self (lambda () (funcall free pointer)))))

(defclass language (foreign-object) ())
(defclass parser (foreign-object) ())
(defclass point (foreign-object) ())
(defclass node (foreign-object) ())
(defclass tree (foreign-object) ())
(defclass cursor (foreign-object) ())

;********************;
;* Section - Parser *;
;********************;

(defun make-parser (&key language timeout cancellation logger)
  (make-instance 'parser
                 :free #'ts-parser-delete
                 :pointer (ts-parser-new :language language
                                         :timeout timeout
                                         :cancellation cancellation
                                         :logger logger)))

(defun parser-language (parser)
  (ts-parser-language (pointer parser)))

(defun (setf parser-language) (value parser)
  (ts-parser-set-language (pointer parser) value))

(defun parser-timeout (parser)
  (ts-parser-timeout-micros (pointer parser)))

(defun (setf parser-timeout) (value parser)
  (ts-parser-set-timeout-micros (pointer parser) value))

(defun parser-parse-string (parser value &key (old-tree (null-pointer)) encoding)
  (let ((pointer
          (if encoding
              (ts-parser-parse-string-encoded
               (pointer parser) value encoding old-tree)
              (ts-parser-parse-string (pointer parser) value old-tree))))
    (make-instance 'tree
                   :free #'ts-tree-delete
                   :pointer pointer)))

(defun parser-reset (parser)
  (ts-parser-reset (pointer parser)))

;******************;
;* Section - Tree *;
;******************;

(defun tree-root-node (tree &key offset)
  (let ((pointer
          (if offset
              (ts-tree-root-node-with-offset (pointer tree) offset (null-pointer))
              (ts-tree-root-node (pointer tree)))))
    (make-instance 'node :pointer pointer)))

(defun tree-language (tree)
  (make-instance 'language
                 :free #'ts-language-delete
                 :pointer (ts-language-copy (ts-tree-language (pointer tree)))))

;******************;
;* Section - Node *;
;******************;

(defun node-type (node)
  (ts-node-type (pointer node)))

(defun node-symbol (node)
  (ts-node-symbol (pointer node)))

(defun node-language (node)
  (make-instance 'language
                 :free #'ts-language-delete
                 :pointer (ts-language-copy (ts-node-language (pointer node)))))

(defun node-grammar-type (node)
  (ts-node-grammar-type (pointer node)))

(defun node-grammar-symbol (node)
  (ts-node-grammar-symbol (pointer node)))

(defun node-start-byte (node)
  (ts-node-start-byte (pointer node)))

(defun node-end-byte (node)
  (ts-node-end-byte (pointer node)))

(defun node-start-point (node)
  (let ((point (ts-node-start-point (pointer node))))
    (prog1 (cons (ts-point-row point) (ts-point-column point))
      (ts-point-delete point))))

(defun node-end-point (node)
  (let ((point (ts-node-end-point (pointer node))))
    (prog1 (cons (ts-point-row point) (ts-point-column point))
      (ts-point-delete point))))

(defun node-string (node)
  (ts-node-string (pointer node)))

(defun node-null-p (node)
  (ts-node-is-null (pointer node)))

(defun node-named-p (node)
  (ts-node-is-named (pointer node)))

(defun node-missing-p (node)
  (ts-node-is-missing (pointer node)))

(defun node-extra-p (node)
  (ts-node-is-extra (pointer node)))

(defun node-has-changes (node)
  (ts-node-has-changes (pointer node)))

(defun node-has-error (node)
  (ts-node-has-error (pointer node)))

(defun node-error-p (node)
  (ts-node-is-error (pointer node)))

(defun node-parent (node)
  (make-instance 'node :pointer (ts-node-parent (pointer node))))

(defun node-child (node index)
  (make-instance 'node :pointer (ts-node-child (pointer node) index)))

(defun node-child-count (node)
  (ts-node-child-count (pointer node)))

(defun node-next-sibling (node)
  (make-instance 'node :pointer (ts-node-next-sibling (pointer node))))

(defun node-prev-sibling (node)
  (make-instance 'node :pointer (ts-node-prev-sibling (pointer node))))

(defun node-eq (node other)
  (ts-node-eq (pointer node) other))

;************************;
;* Section - TreeCursor *;
;************************;

(defun make-cursor (node)
  (make-instance 'cursor
                 :free #'ts-tree-cursor-delete
                 :pointer (ts-tree-cursor-new (pointer node))))

(defun cursor-reset (cursor node)
  (ts-tree-cursor-reset (pointer cursor) (pointer node)))

(defun cursor-node (cursor)
  (make-instance 'node :pointer (ts-tree-cursor-current-node (pointer cursor))))

(defun cursor-field-name (cursor)
  (ts-tree-cursor-current-field-name (pointer cursor)))

(defun cursor-field-id (cursor)
  (ts-tree-cursor-current-field-id (pointer cursor)))

(defun cursor-goto-parent (cursor)
  (ts-tree-cursor-goto-parent (pointer cursor)))

(defun cursor-goto-next-sibling (cursor)
  (ts-tree-cursor-goto-next-sibling (pointer cursor)))

(defun cursor-goto-prev-sibling (cursor)
  (ts-tree-cursor-goto-previous-sibling (pointer cursor)))

(defun cursor-goto-first-child (cursor)
  (ts-tree-cursor-goto-first-child (pointer cursor)))

(defun cursor-goto-last-child (cursor)
  (ts-tree-cursor-goto-last-child (pointer cursor)))

(defun cursor-goto-descendant (cursor index)
  (ts-tree-cursor-goto-descendant (pointer cursor) index))

(defun cursor-descendant-index (cursor)
  (ts-tree-cursor-current-descendant-index (pointer cursor)))

(defun cursor-depth (cursor)
  (ts-tree-cursor-current-depth (pointer cursor)))

(defun cursor-goto-first-child-for-byte (cursor byte)
  (ts-tree-cursor-goto-first-child-for-byte (pointer cursor) byte))

(defun cursor-goto-first-child-for-point (cursor point)
  (ts-tree-cursor-goto-first-child-for-point
   (pointer cursor)
   (make-instance 'point
                  :free #'ts-point-delete
                  :pointer (ts-point-new (car point) (cdr point)))))

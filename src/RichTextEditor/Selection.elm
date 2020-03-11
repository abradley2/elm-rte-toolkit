module RichTextEditor.Selection exposing
    ( annotateSelection
    , clearSelectionAnnotations
    , domToEditor
    , editorToDom
    , selectionFromAnnotations
    )

import RichTextEditor.Annotation
    exposing
        ( addAnnotationAtPath
        , clearAnnotations
        , findPathsWithAnnotation
        )
import RichTextEditor.Model.Annotation exposing (selectionAnnotation)
import RichTextEditor.Model.Node exposing (BlockNode, Path)
import RichTextEditor.Model.Selection exposing (Selection, anchorNode, anchorOffset, focusNode, focusOffset, rangeSelection)
import RichTextEditor.Model.Spec exposing (Spec)
import RichTextEditor.NodePath as Path


domToEditor : Spec -> BlockNode -> Selection -> Maybe Selection
domToEditor =
    transformSelection Path.domToEditor


editorToDom : Spec -> BlockNode -> Selection -> Maybe Selection
editorToDom =
    transformSelection Path.editorToDom


transformSelection : (Spec -> BlockNode -> Path -> Maybe Path) -> Spec -> BlockNode -> Selection -> Maybe Selection
transformSelection transformation spec node selection =
    case transformation spec node (anchorNode selection) of
        Nothing ->
            Nothing

        Just an ->
            case transformation spec node (focusNode selection) of
                Nothing ->
                    Nothing

                Just fn ->
                    Just <| rangeSelection an (anchorOffset selection) fn (focusOffset selection)


annotateSelection : Selection -> BlockNode -> BlockNode
annotateSelection selection node =
    addSelectionAnnotationAtPath (focusNode selection) <| addSelectionAnnotationAtPath (anchorNode selection) node


addSelectionAnnotationAtPath : Path -> BlockNode -> BlockNode
addSelectionAnnotationAtPath nodePath node =
    Result.withDefault node (addAnnotationAtPath selectionAnnotation nodePath node)


clearSelectionAnnotations : BlockNode -> BlockNode
clearSelectionAnnotations =
    clearAnnotations selectionAnnotation


selectionFromAnnotations : BlockNode -> Int -> Int -> Maybe Selection
selectionFromAnnotations node anchorOffset focusOffset =
    case findNodeRangeFromSelectionAnnotations node of
        Nothing ->
            Nothing

        Just ( start, end ) ->
            Just (rangeSelection start anchorOffset end focusOffset)


findNodeRangeFromSelectionAnnotations : BlockNode -> Maybe ( Path, Path )
findNodeRangeFromSelectionAnnotations node =
    let
        paths =
            findPathsWithAnnotation selectionAnnotation node
    in
    case paths of
        [] ->
            Nothing

        [ x ] ->
            Just ( x, x )

        end :: start :: _ ->
            Just ( start, end )
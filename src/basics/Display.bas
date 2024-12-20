' Main procedure: handles navigation and propagates errors
Sub ButtonGoToSourceCell()

    ' Setup workflow
    On Error GoTo ErrorHandler ' Enable error handling for the procedure

    ' Find and select the target cell
    Dim targetCell As Range
    Set targetCell = GetTargetCell() ' May raise an error
    
    ' Select the row in the table
    Call SelectTableRow(targetCell) ' May raise an error
    
    Exit Sub ' Exit successfully

ErrorHandler:
    ' Handle any errors from nested functions
    MsgBox "Error: " & Err.Description, vbExclamation, "An Error Occurred"
End Sub

' Main procedure to toggle the display of service (‘helper’) columns
Sub ToggleVisibilityMode()

    ' Setup workflow
    Dim ws As Worksheet
    Dim settings As ListObject
    Dim column As ListColumn
    Dim newState As Boolean
  
    ' Access the document settings
    Set settings = ActiveWorkbook.Sheets("@core").ListObjects("settings")
    Set column = settings.ListColumns("show_lid_columns")
  
    ' Toggle the visibility state
    newState = Not column.DataBodyRange.Cells(1, 1).Value
    column.DataBodyRange.Cells(1, 1).Value = newState
  
    ' Iterate through all sheets in the workbook
    For Each ws In ActiveWorkbook.Sheets
        Dim table As ListObject
        For Each table In ws.ListObjects
            For Each column In table.ListColumns
            ' Check if the column name contains ":lid"
            If InStr(1, column.name, ":lid") Or InStr(1, column.name, "sig") Then
                column.Range.EntireColumn.Hidden = Not newState
            End If
        Next column
      Next table
    Next ws

End Sub

' Function to find the target cell based on validation
Function GetTargetCell() As Range

    ' Setup workflow
    Dim validationRange As Range
    Dim targetCell As Range
    Dim validationFormula As String

    On Error GoTo ErrorHandler ' Enable error handling for this function

    ' Check if the active cell has Data Validation
    If ActiveCell.Validation.Type = xlValidateList Then
        validationFormula = ActiveCell.Validation.Formula1
    Else
        Err.Raise vbObjectError + 513, "GetTargetCell", "Active cell does not have valid Data Validation."
    End If

    ' Extract the validation range
    If Left(validationFormula, 1) = "=" Then
        Set validationRange = Range(Mid(validationFormula, 2))
    Else
        Err.Raise vbObjectError + 514, "GetTargetCell", "Data Validation is not linked to a range."
    End If

    ' Search for the value in the validation range
    Set targetCell = validationRange.Find(What:=ActiveCell.Value, LookIn:=xlValues, LookAt:=xlWhole)
    If targetCell Is Nothing Then
        Err.Raise vbObjectError + 515, "GetTargetCell", "Value not found in the validation range."
    End If

    ' Return the found cell
    Set GetTargetCell = targetCell
    Exit Function

ErrorHandler:
    ' Raise the error to the calling procedure
    Err.Raise Err.Number, "GetTargetCell", Err.Description
End Function

' Function to select the table row for a target cell
Function SelectTableRow(targetCell As Range)

    ' Setup workflow
    Dim table As ListObject
    Dim row As ListRow

    On Error GoTo ErrorHandler ' Enable error handling for this function

    ' Check if the target cell belongs to a table
    Set table = targetCell.ListObject
    If table Is Nothing Then
        Err.Raise vbObjectError + 516, "SelectTableRow", "The target cell does not belong to a table."
    End If

    ' Get the table row that contains the target cell
    Set row = table.ListRows(targetCell.row - table.HeaderRowRange.row)

    ' Select the entire row of the table
    If Not row Is Nothing Then
        row.Range.Select
    Else
        Err.Raise vbObjectError + 517, "SelectTableRow", "The target cell is not within the data body of the table."
    End If

    Exit Function

ErrorHandler:
    ' Raise the error to the calling procedure
    Err.Raise Err.Number, "SelectTableRow", Err.Description
End Function

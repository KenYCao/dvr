' ####################################################################
' VBScript Sub Procedure
'	to convert each worksheets in configuration to individual csv file
'	created on 2014/04/23 by Ken Cao (yong.cao@q2bi.com)
' Paramter:
'	    config : confguration file full path name
'      tempDir : temporary directory to save csv file
'   fileformat : 6 --> normal csv; 42 --> text in unicode format (ucs-2)
'
' Revision History£º
' Ken Cao on 2015/01/21: Add a parameter fileformat (optional value are 
'                        6 and 42)
' ####################################################################

' save text as utf-8 text file.
Sub Save2File (sText, sFile)
    Dim oStream
    Set oStream = CreateObject("ADODB.Stream")
    With oStream
        .Open
        .CharSet = "utf-8"
        .WriteText sText
        .SaveToFile sFile, 2
    End With
    Set oStream = Nothing
End Sub


Sub Unicode2Any(myFileIn, myFileOut, charset)

	Const adTypeBinary = 1   
	Const adTypeText   = 2   
	Const bOverwrite   = True   
	Const bAsASCII     = False   
	 
	Dim oFS     : Set oFS    = CreateObject( "Scripting.FileSystemObject" )    
	Dim oFrom   : Set oFrom  = CreateObject( "ADODB.Stream" )   
	Dim sFrom   : sFrom      = "Unicode"   
	'Dim oTemp   : Set oTemp  = CreateObject( "ADODB.Stream" )   
	'Dim sTemp   : sTemp      = "Unicode"   
	Dim oTo     : Set oTo    = CreateObject( "ADODB.Stream" )   
	Dim sTo     : sTo        = charset
	 
	oFrom.Type    = adTypeText   
	oFrom.Charset = sFrom   
	oFrom.Open   
	oFrom.LoadFromFile myFileIn
	text = oFrom.ReadText    
	oFrom.Close
	set oFrom = Nothing
	
	oFS.DeleteFile myFileIn 
	
	oTo.Type    = adTypeText   
	oTo.Charset = sTo   
	oTo.Open   
	oTo.WriteText text   
	oTo.SaveToFile myFileOut
	oTo.Close 
	
End Sub

Sub expCFG2csv(config, tempDir, fileformat)
	Dim objExcel 
	Dim CFG 
	Dim wbTMP
	Dim wksh

	' create an excel application object
	Set objExcel = CreateObject("Excel.Application")

	' invisible and suppress message
	objExcel.Visible = False
	objExcel.DisplayAlerts = False

	' open configuration file
	Set CFG = objExcel.Workbooks.Open(config)
	
	For Each wksh In CFG.Worksheets
		' Ken on 2014/04/24: Set cell format (number£©of all cells to be "General".
		wksh.Cells.NumberFormat = "General"
		'wksh.SaveAs tempDir & "\" & wksh.name & ".csv", 6
		wksh.SaveAs tempDir & "\" & wksh.name & ".csv", fileformat
	Next
	

	' close opened workbook and quit excel application
	objExcel.ActiveWorkbook.Close
	
	
	' Save unicode text to utf-8 text
	Set CFG = objExcel.Workbooks.Open(config)
	For Each wksh In CFG.Worksheets
		If fileformat = 42 Then
			Unicode2Any tempDir & "\" & wksh.name & ".csv", tempDir & "\" & wksh.name & ".csv", "utf-8"
		End If
		
	Next
	objExcel.ActiveWorkbook.Close
	objExcel.Quit
	
	' release memorary
	Set objExcel = Nothing
	Set CFG = Nothing
End Sub


*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Tables
Library           RPA.Browser.Selenium
Library           RPA.FileSystem
Library           RPA.PDF
Library           RPA.Archive
Library           BuiltIn
Library           RPA.RobotLogListener
Library           RPA.Robocorp.Vault
Library           RPA.Dialogs

*** Variables ***
${RANGE}=         6

*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    RSB_Orders
    Open Chrome Browser    ${secret}[rsb_website]

Assistant Input for CSV File
    Add image    C:\\Users\\rkind\\Documents\\Robots\\RSB_Order_Bot\\robot4.png
    Add heading    RSB Orders File Path    size=Medium
    Add text input    filepath    label=Get_Orders
    ${response}=    Run dialog
    [Return]    ${response.filepath}

Get Order CSV File
    [Arguments]    ${Get_Orders}
    Open Chrome Browser    ${Get_Orders}
    Wait Until Created    C:\\Users\\rkind\\Downloads\\orders.csv
    Close Browser
    [Return]    ${Get_Orders}

Get the Order Items
    [Arguments]    @{orders}
    ${status}=    Does File Exist    C:\\Users\\rkind\\Downloads\\orders.csv
    IF    ${status} == True
        ${orders}=
        ...    Read Table From Csv
        ...    C:\\Users\\rkind\\Downloads\\orders.csv
        ...    header=True
    END
    Remove File    C:\\Users\\rkind\\Downloads\\orders.csv
 #    Log    ${orders}
    [Return]    ${orders}

Close the alert panel
    ${panel}=    RPA.Browser.Selenium.Is Element Visible    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    IF    ${panel} == True
        Click Button    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    END

Fill the Form
    [Arguments]    ${row}
    Select From List By Index    id:head    ${row}[Head]
    Select Radio Button    body    id-body-${row}[Body]
    Input Text    class:form-control    ${row}[Legs]
    Input Text    name:address    ${row}[Address]
    [Return]    ${row}

Preview Order
    Wait Until Element Is Visible    id:preview
    Click Button    id:preview

Submit Order
    Wait Until Element Is Visible    id:order
    Click Button    id:order
    ${alert}=    RPA.Browser.Selenium.Is Element Visible    css:.alert.alert-danger
    FOR    ${i}    IN RANGE    ${RANGE}
        IF    ${alert} == True
            Sleep    0.5 sec
            Mute Run On Failure    Click Element When Visible
            Run Keyword And Ignore Error    RPA.Browser.Selenium.Click Element When Visible    id:order
        END
        ${alert}=    RPA.Browser.Selenium.Is Element Visible    css:.alert.alert-danger
        Exit For Loop If    ${alert} == False
    END

Convert Receipts to PDF
    [Arguments]    ${row}
    Set Screenshot Directory    ${OUTPUT_DIR}${/}Receipts
    Wait Until Keyword Succeeds    3x    0.5 sec    Wait Until Element Is Visible    id:receipt
    ${Receipt_HTML}=    Get Element Attribute    id:receipt    outerHTML
 #    Log    ${Receipt_HTML}
    Html To Pdf    ${Receipt_HTML}    ${OUTPUT_DIR}${/}Receipts/receipts${row}[Order number].pdf

Robot Screenshot in Pdf
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:robot-preview-image
    Capture Element Screenshot    id:robot-preview-image    robot${row}[Order number].png
    Add Watermark Image To Pdf
    ...    image_path=${OUTPUT_DIR}${/}Receipts/robot${row}[Order number].png
    ...    source_path=${OUTPUT_DIR}${/}Receipts/receipts${row}[Order number].pdf
    ...    output_path=${OUTPUT_DIR}${/}Receipts/receipts${row}[Order number].pdf

Go to Order Another Robot
    Wait Until Element Is Visible    id:order-another
    Click Button    id:order-another

Create ZIP FIle of All Receipts
    Archive Folder with ZIP    ${OUTPUT_DIR}${/}Receipts/    ${OUTPUT_DIR}${/}Receipts/Receipts.ZIP
    Close Browser

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${Get_Orders}=    Assistant Input for CSV File
    Get Order CSV File    ${Get_Orders}
    ${orders}=    Get the Order Items
    Open the robot order website
    FOR    ${row}    IN    @{orders}
        Close the alert panel
        Fill the Form    ${row}
        Preview Order
        Submit Order
        Convert Receipts to PDF    ${row}
        Robot Screenshot in Pdf    ${row}
        Go to Order Another Robot
    END
    Create ZIP File of All Receipts

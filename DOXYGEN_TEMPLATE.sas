/**
* @file template.sas
* @brief One-line description of what the macro does
*
* @details
* More detailed description of the macro's functionality.
* This can span multiple lines and explain the purpose,
* approach, and any important implementation details.
*
* @param[in] param1 Description of parameter 1 (Required)
* @param[in] param2 Description of parameter 2 (Default: value)
* @param[in] param3 Description of parameter 3 (Optional)
*
* @return Description of what the macro returns or creates
*
* @examples
* @code
* %template(param1=value1, param2=value2);
* %template(param1=different_value);
* @endcode
*
* @author Author Name
* @date DD-MMM-YYYY
*/

%macro template(param1 /*Required. Description*/,
                param2=default /*Default: default. Description*/,
                param3= /*Optional. Description*/);

    /* Macro implementation */

%mend template;

#!/usr/bin/env python3
import re

# Read the project file
with open('IngredientCheck.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Find the IngredientCheck group section and add the new files
# Look for the line with Info.plist and add our files after it
pattern = r'(29AC08AD89804E0C859D685F /\* Info\.plist \*/,\n)'
replacement = r'\g<1>\t\t\t78161C51F7B44DA9BB14806E /* RegulatorySubstance.swift */,\n\t\t\t9E921CFE26EB4D9E871513FE /* RegulatoryBadgeView.swift */,\n\t\t\tA11B83C27A0F41EA9CED4D76 /* ECHA_Regulatory_Data.json */,\n'

content = re.sub(pattern, replacement, content)

# Write back
with open('IngredientCheck.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✅ Added files to IngredientCheck group")

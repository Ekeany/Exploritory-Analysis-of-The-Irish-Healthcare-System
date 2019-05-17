# Exploritory-Analysis-of-The-Irish-Healthcare-System.
### Authors Yifei Zhou and Eoghan Keany.

## Introduction.

The current structure of the Irish healthcare system ensures that people spend an unjustifiable amount of time not being treated for their ailments. Patients are viewed as a cost that is only realized when a patient enters the healthcare system. Everyone accepts that the Irish healthcare system is failing, however the only thing that divides us is how to approach the problem. The aim of this assignment was to highlight and visualize trends in the OP Waiting List dataset available on National Open Data portal. The OP Waiting List dataset refers to the total number of patients waiting, across the various time bands, for a first appointment at a consultant-led Outpatient clinic. With each report listing the numbers waiting per Hospital in each particular specialty. The tasks involved within this assignment were to connect to the CKAN platform using their own API.

1. Access the necessary datasets and associated files.
2. Preprocessing steps such as fixing mistaken age group labels and removing Na values
3. Integrate, analyse and aggregate the chosen files by hospital.
4. Finally a number of charts were created to display the changes in waiting list over time.

The final aggregated data set contained multidimensional data about the number of patients waiting for a procedure on a specific day of a specific year. The number of people waiting for a procedure was distributed among numerous categories such as age, time band, specialty, hospital and year. This inherent dimensionality proved challenging, as decisions about which aspects should be chosen to represent the data had to be addressed. Seven aggregated tables were created each using the mean value of the patient waiting times, as this value seemed more appropriate. Each table was grouped and aggregated on a different aspect of the dataset and saved to csv. For the final report Seven visualizations in total were then created from the aggregated tables, with each visualization encapsulating an important aspect of the dataset.

## Results.

The first plot questions the current accessibility of hospitals in Ireland, by examining the spatial distribution of public hospitals on a county level as a function of county population. The data clearly indicates that the distribution of both hospitals and population are not equal throughout the country. This is common knowledge; as people are moving from rural areas to urban areas in a process called urbanization. (Fig,1) also displays a few problematic areas where the number of people per hospital is large. The counties most affected are Donegal, Tipperary, Kerry and Kildare, Monaghan and Leitrim. As the majority of these counties are within a reasonable distance to medical hubs such as Limerick, Galway, Dublin and Cork there problems are mitigated, however Donegal, Leitrim and Monaghan are somewhat isolated from the rest of the country exacerbating the pressure on other local services.

<p align="center">
  <img width="460" height="300" src="/Images_/image1/PNG">
</p>

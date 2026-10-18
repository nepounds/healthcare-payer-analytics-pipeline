# v0.2bigdaddy Skill Coverage

## Skills strengthened beyond v0.1

### SQL

v0.2bigdaddy naturally adds:

- more complex window functions;
- `LAG` for episode spacing/new-event logic;
- larger aggregation workloads;
- multiple fact grains;
- performance inspection;
- indexing decisions;
- data-quality procedures/views;
- reusable dimensional marts.

### Excel

Use separate validation tabs/queries by domain rather than one giant workbook.

Natural exercises include:

- merges across SQL outputs and source extracts;
- exception summaries;
- pivot/slicer QA;
- PMPM/member-month controls;
- aging bucket checks;
- provider/count reconciliation.

Do not attempt to validate millions of raw rows directly on worksheets.

### Power BI

Natural additions:

- multiple fact tables;
- conformed dimensions;
- more advanced filter context;
- time intelligence;
- page navigation;
- domain-specific drillthrough;
- reusable theme;
- metric definition tooltips/documentation.

### Data engineering / governance

Natural additions:

- run metadata;
- data-quality gates;
- configuration;
- role separation;
- lineage;
- restart/rebuild behavior;
- scale testing.

## Skills that still should not be forced

Examples:

- cloud services, if local operation remains a project requirement;
- Spark, because the dataset does not need it;
- Kubernetes;
- enterprise orchestration platforms;
- machine learning unless a separate use case genuinely justifies it.

The project should look like a thoughtful analyst/data project, not a résumé-keyword collection.

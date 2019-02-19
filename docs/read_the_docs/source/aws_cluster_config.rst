AWS Cluster Configuration
#########################

Depending on the size of your analysis, you can adjust selections for **Server Instance Type**, **Worker Instance Type**, and/or **Number of Workers**. Large analyses with many simulations may require more computing power. Keep in mind that more computing power may lead to faster analysis runtimes, but generally will cost more money.

.. image:: images/remote_server_settings_docs_request.png

You can use the following guidance to decide what combination of settings makes sense for your analysis:

 - For smaller analyses where the number of simulations is between 1 and 10,000, use the c3.8xlarge server and worker instance type. This instance type should be selected by default. You can also leave the number of workers at its default value of zero.
 - For larger analyses where the number of simulations is between 1,000 and 100,000, use the d2.4xlarge server instance type, c3.8xlarge worker instance type, and up to 10 workers. Using the d2.4xlarge server with more memory is necessary to manage larger analyses. 

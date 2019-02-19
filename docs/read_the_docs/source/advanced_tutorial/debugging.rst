Debugging
#########

Simulations may not always run successfully (even if the integrity checks pass). Reasons may include bad weather files, invalid measure arguments, untested measure combinations, etc. The OpenStudio-server GUI will indicate unsuccessful datapoints by showing "datapoint failure" under the "Status Message" column when you click on the homepage's "View Analysis" button. Options for investigating causes of datapoint failures include:

 - :ref:`Simulation Datapoint Log File <sdp-log-file>`
 - :ref:`Run Simulations Locally <run-simulations-locally>`

.. _sdp-log-file:

Simulation Datapoint Log File
=============================

To investigate the issues behind failed datapoints, click "View" for any datapoint failure rows. Scroll down and select the "sdp_log_file" button:

.. image:: ../images/advanced_tutorial/sdp_log_file_example.png

Search the log's text for the error. Diagnose the problem and fix it. Depending on where the issue originates, you may need to address problems upstream in the OpenStudio-BEopt's ``measures`` directory. If that's the case, you'll probably want to start this entire development process over beginning with :doc:`rake_tasks`. Bummer.

.. _run-simulations-locally:

Run Simulations Locally
=======================

Each datapoint will come with a ``measures.osw`` file. You can `pull these down <../tutorial/run_project.html#download>`_ from the server and run them locally.
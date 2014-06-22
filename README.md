bpmwatcher
==========

HP BPM (Business Process Monitor)  watcher is the powershell script that analyses the responses from BPMs to HP BSM / HP BAC and shows the inactivity of specific BPM. 
The purpose: to know when particular Business Process Monitor stopped responding and to know how long particular transaction/script hasn’t been executed or returned data. 
The weapon of choice: 
* powershell 
* BSM OpenAPI.

==========
### Variables

* $strict - You can assign value 0 or 1. If it is set to 1 it forces the script to report the Business Process Monitor as faulty only when it stopped responding within all scripts/transactions that has been deployed to it. If it is set to 0, the script will report the Business Process Monitor as faulty even it if stopped executing only one of deployed scripts/transactions.
* $url - Default value is : `$url = "https://BAC.URL/gdeopenapi/GdeOpenApi?method=getData&user=XXX&password=XXX&query=SELECT DISTINCT szTransactionName as transaction, MAX(time_stamp) as time FROM trans_t WHERE profile_name='" + $profile + "' and time_stamp>" + $weekAgo + " &resultType=csv&customerID=1"` Of course you need to supply address to your own instance of HP BAC and your credentials.


==========

### About 

For those of You that work with application performance monitoring or synthetic user experience monitoring the name of HP Business Availability Center (BAC – formerly known as Mercury Topaz) or HP Business Service Management (BSM – as it is called nowadays), might sound somewhat familiar. One of the features that this suite includes is Business Process Monitor (sometimes referred to as probe). BPM is a piece of software that is capable of running recorded scripts, the execution of which is measured and reported back to central side server – BAC/BSM. This allows you to diagnose and narrow down the cause of performance drops, network bottlenecks or availability issues both overall and from the specific BPM.

To make it more clear:
Lets say you have an application that is available to your clients all over the world. You need to sustain an availability and performance on a level specified in the SLA. You buy BAC/BSM licence and install Business Process Monitor within your clients’ network infrastructures. This will allow you to track performance of your application from multiple sites (cross-country or across the world). Scripts are commonly recorded with HP LoadRunner and deployed to BPMs and executed. The data reported by Business Process Monitor to central server can show you how long did it take to access your application from specific location, how long did it take for your server to respond, how much time did the SSL handshake consumed, what were the errors encountered during the script execution and what errors did the end user saw when your application had issues. Overall a really, really great tool.

But… at some point when number of Your applications increases and with those the number of BPMs and sustained transactions as well (transaction is a block of code within the script that contains particular actions – for example authentication process, or data submit to web page – and is shown separately on the server side), You will face imminent problem with tracking how much BPMs still work, how much have been shutdown accidentally (or intentionally) by your client or which transactions are missing data and when did they stop reporting. The job of reviewing all of the BPMs scattered across multiple transactions, and multiple applications, and multiple profiles (profile is a group of application or group of scripts) is a tedious and painfully boring. I had to review hundreds of transactions and hundreds of BPMs each month – trust me, there are better ways of spending half day at work. Daily routine kills the joy in you piece by piece.

Therefore I've written this script.

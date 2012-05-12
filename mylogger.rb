require 'logger'

#require 'params'
#PARAMS.parameter("log_file", "/log/file_copy.log", "Specifies log file for file_copy module.")

#LOG_FILE = 'log/logger.log'
LOG_FILE = STDOUT

#@LOG = Logger.new(PARAMS.log_file, 'monthly')
LOG = Logger.new(LOG_FILE, 'monthly')
LOG.level = Logger::DEBUG
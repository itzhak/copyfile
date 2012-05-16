# Author: Itzhak B. 
# Description: copy data and files by tcpip protocol
# Run: ruby examples/receiver.rb, ruby examples/sender.rb
 
require 'socket'
require 'thread'
require File.dirname(__FILE__) + '/mylogger.rb'

MIN_PORT_NUM = 49152 #range of legal open ports 
MAX_PORT_NUM = 65535

# host that send datat and files
class Sender
  def initialize(addr, port_num)
    @LOG = LOG
    if port_num < MIN_PORT_NUM || port_num > MAX_PORT_NUM
      @LOG.error("port number #{port_num} should be beetwen #{MIN_PORT_NUM} and beetwen \
                 #{MAX_PORT_NUM}")      
      raise "port number #{port_num} should be beetwen #{MIN_PORT_NUM} and beetwen #{MAX_PORT_NUM}"      
    end
    @socket = TCPSocket.open addr, port_num
    addr = @socket.addr
    addr.shift  # removes "AF_INET"
    @LOG.info("socket open on addr: #{addr.join(":")}")
    peer_addr = @socket.peeraddr
    peer_addr.shift  # removes "AF_INET"
    @LOG.debug("connected to peer: #{peer_addr.join(":")}")
  end
  
  def send(data)
    @LOG.debug("data to send is (#{data}).")
    marshal_data = Marshal.dump(data)
    data_size = [marshal_data.length].pack("l")
    @socket.write(data_size)
    @socket.write(marshal_data)
  end
  
  def send_file(file_name)
    #check if source file is exist
    if (File.exists?(file_name) == false)
      @LOG.warn("source file \'#{file_name} \' Does not exist")
      return -1
    end    
    
    file = File.open(file_name, "r")    
    content = file.read
    send(content)    
  end
  
  def close
    @socket.close
  end
end

# multiclient server that receive data 
class Receiver
  def initialize port_num
    @LOG = LOG
    if port_num < MIN_PORT_NUM || port_num > MAX_PORT_NUM
      @LOG.error("port number #{port_num} should be beetwen #{MIN_PORT_NUM} and beetwen\
                   #{MAX_PORT_NUM}")      
      raise "port number #{port_num} should be beetwen #{MIN_PORT_NUM} and beetwen #{MAX_PORT_NUM}"      
    end
    @port_num = port_num
    @server = TCPServer.open 'localhost', port_num
    addr = @server.addr
    addr.shift            # removes "AF_INET"
    @LOG.info("server is on #{addr.join(":")}")
  end
  
  # start server, when data received it pushed to queue
  def run (queue)
    loop do
      @LOG.debug "waiting on #{@port_num}"
      Thread.start(@server.accept) do |client|
        addr = client.addr
        addr.shift  # removes "AF_INET"
        @LOG.info("accept connection addr: #{addr.join(":")}")
        peer_addr = client.peeraddr
        peer_addr.shift  # removes "AF_INET"
        @LOG.debug("connected to peer: #{peer_addr.join(":")}")
        while size = client.recv(4).unpack("l")[0]
          @LOG.debug "begin receiving data with size #{size}"
          data = client.recv(size)
          unmarshaled_data = Marshal.load(data)
          @LOG.debug "data received (#{unmarshaled_data})"
          queue.push unmarshaled_data
        end
        @LOG.info "connection #{peer_addr.join(":")} is closed by other side"         
      end           
    end
  end
end

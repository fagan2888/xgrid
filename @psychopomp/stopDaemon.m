function stopDaemon(self)

stop(self.daemon_handle);
delete(self.daemon_handle);

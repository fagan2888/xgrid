%
% __   ____ _ _ __(_) __| |
% \ \/ / _` | '__| |/ _` |
%  >  < (_| | |  | | (_| |
% /_/\_\__, |_|  |_|\__,_|
%      |___/
%
% ### stopDaemon
%
%
% **Syntax**
%
% ```matlab
% 	p.stopDaemon()
% ```
%
% **Description**
%
% Forcibly stops all running daemons.
%
% **Technical Details**
%
% This function is *internal*.
% Users should call `delete` instead.
%
% See Also:
% xgrid.delete

function stopDaemon(self)

stop(self.daemon_handle);
delete(self.daemon_handle);

% trigger a rebuild in the cpplab cache
cpplab.rebuildCache()

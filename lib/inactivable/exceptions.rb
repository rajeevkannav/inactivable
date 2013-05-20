module Exceptions

  class NotAnActiveRecordClassError < StandardError;
  end
  class DeactivatedAlreadyError < StandardError;
  end
  class BackupConnectionFailedToEstablishError < StandardError;
  end
  class ActivatedAlreadyError < StandardError;
  end

end

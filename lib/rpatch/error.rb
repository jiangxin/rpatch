module Rpatch
  class AlreadyPatchedError < Exception; end
  class PatchHunkError < Exception; end
  class PatchFormatError < Exception; end
  class FileNotExistError < Exception; end
  class PatchFailNotify < Exception; end
  class PatchOneWithManyError < Exception; end
end

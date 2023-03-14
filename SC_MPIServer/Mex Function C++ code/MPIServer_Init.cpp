#include "mex.hpp"
#include "mexAdapter.hpp"

using namespace matlab::data;
using matlab::mex::ArgumentList;

extern "C"
{
    void MPIServer_Init(size_t *C_filename_len, char *C_filename, size_t *nT, size_t *nc, int *ierror);
}

class MexFunction : public matlab::mex::Function
{
    std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
    ArrayFactory factory;
    std::ostringstream stream;

public:
    void operator()(ArgumentList outputs, ArgumentList inputs)
    {
        // fortran output variables
        size_t nT;
        size_t nc;
        int ierror;

        // formatting matlab input as fortran input
        const CharArray filename = inputs[0];
        size_t filename_length = filename.getNumberOfElements() + 1;
        char *filename_fortran = new char[filename_length];
        for (int i = 0; i < filename_length-1; ++i)
        {
            filename_fortran[i] = filename[i];
        }
        filename_fortran[filename_length-1] = '\0';

        // calling mpiserver init from fortran
        MPIServer_Init(&filename_length, filename_fortran, &nT, &nc, &ierror);

        if (ierror != 0)
        {
            stream << "An error occured in MPIServer_Init\n";
            displayOnMATLAB(stream);
        }

        delete[] filename_fortran;

        // the outputs of the function, these are the outputs the mexx function should have
        outputs[0] = factory.createScalar(nT);
        outputs[1] = factory.createScalar(nc);
    }

    void displayOnMATLAB(std::ostringstream &stream)
    {
        // Pass stream content to MATLAB fprintf function
        matlabPtr->feval(u"fprintf", 0,
                         std::vector<Array>({factory.createScalar(stream.str())}));
        // Clear stream buffer
        stream.str("");
    }
};
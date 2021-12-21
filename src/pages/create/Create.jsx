import PageBanner from '../../components/Common/PageBanner';
import CreateCollectionArea from '../../components/CreateCollection/CreateCollectionArea';

const Create = () => {
    return (
        <div className="author-color">
            <PageBanner
                bannerHeading='Recent Activity'
                parentTitle='Activity'
                pageTitle=''
                bg='inner-bg13'
            />
            <CreateCollectionArea/>
        </div>
    )
}

export default Create;

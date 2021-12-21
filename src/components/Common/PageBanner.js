import React from 'react';
import { Link } from "react-router-dom";

const PageBanner = ({ bannerHeading, parentTitle, pageTitle,bg }) => {
  return (
    <>
      <div className={`inner-banner ${bg}`}>
        <div className='container'>
          <div className='inner-title'>
            <h3>{bannerHeading}</h3>
          
          </div>
        </div>
      </div>
    </>
  );
};

export default PageBanner;

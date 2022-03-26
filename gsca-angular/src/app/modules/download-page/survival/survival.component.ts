import { Component, OnInit } from '@angular/core';
import survivaltable from 'src/app/shared/constants/survival-download';
import { DownloadTableRecord } from 'src/app/shared/model/downloadTablerecord';
import { MatTableDataSource } from '@angular/material/table';
import { DownloadPageApiService } from '../download-page-api.service';

@Component({
  selector: 'app-survival',
  templateUrl: './survival.component.html',
  styleUrls: ['./survival.component.css'],
})
export class SurvivalComponent implements OnInit {
  // download table
  public mrnatable = new MatTableDataSource<DownloadTableRecord>(survivaltable);
  displayedColumnsMrnaDownload = ['Cancer_type', 'Sample_size', 'File_name', 'download'];
  displayedColumnsMrnaDownloadHeader = ['Cancer type', 'Sample size', 'File name', 'Download'];

  downloadElement: DownloadTableRecord;
  downloadColumn: string;
  downloadURL: string;

  constructor(private downloadPageApiService: DownloadPageApiService) {}

  ngOnInit(): void {}

  ngAfterViewInit(): void {}

  public getdownload(element: DownloadTableRecord, column: string): void {
    this.downloadElement = this.downloadElement === element && this.downloadColumn === column ? null : element;
    this.downloadColumn = column;
    if (this.downloadElement) {
      if (this.downloadColumn === 'download') {
        this.downloadURL = this.downloadPageApiService.getResourceDataURL(this.downloadElement.File_name);
      }
    }
  }
}

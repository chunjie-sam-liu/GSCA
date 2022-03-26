import { Component, OnInit } from '@angular/core';
import mrnatable from 'src/app/shared/constants/mrna-download';
import { DownloadTableRecord } from 'src/app/shared/model/downloadTablerecord';
import { MatTableDataSource } from '@angular/material/table';
import { DownloadPageApiService } from '../download-page-api.service';

@Component({
  selector: 'app-mrna',
  templateUrl: './mrna.component.html',
  styleUrls: ['./mrna.component.css'],
})
export class MrnaComponent implements OnInit {
  // download table
  public mrnatable = new MatTableDataSource<DownloadTableRecord>(mrnatable);
  displayedColumnsMrnaDownload = ['Cancer_type', 'Sample_size', 'File_name', 'download'];
  displayedColumnsMrnaDownloadHeader = ['Cancer type', 'Sample size', 'File name', 'Download'];

  downloadElement: DownloadTableRecord;
  downloadColumn: string;
  downloadURL: string;
  // downloadURL = this.downloadPageApiService.getResourceDataURL(this.expandedElement.File_name);

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
  /*public expandDetail(element: DownloadTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      if (this.expandedColumn === 'download') {
        this.downloadURL = this.downloadPageApiService.getResourceDataURL(this.expandedElement.File_name);
      }
    }
  }*/
}

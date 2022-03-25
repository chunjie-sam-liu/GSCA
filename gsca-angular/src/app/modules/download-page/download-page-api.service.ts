import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BaseHttpService } from 'src/app/shared/base-http.service';

@Injectable({
  providedIn: 'root',
})
export class DownloadPageApiService extends BaseHttpService {
  constructor(http: HttpClient) {
    super(http);
  }

  //download raw data
  public getResourceDataURL(filename: string): string {
    return this.generateRoute('resource/ResponseDataDownload/' + filename);
  }
}

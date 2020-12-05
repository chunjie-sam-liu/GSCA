import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { ImmuneSnvComponent } from './immune-snv.component';

describe('ImmuneSnvComponent', () => {
  let component: ImmuneSnvComponent;
  let fixture: ComponentFixture<ImmuneSnvComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ ImmuneSnvComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ImmuneSnvComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
